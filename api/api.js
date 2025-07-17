import express, { json } from "express";
import multer, { memoryStorage } from "multer";
import fetch from "node-fetch";
import FormData from "form-data";
import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
dotenv.config();

const app = express();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 2 * 1024 * 1024 } });
app.use(express.json());

const PORT = process.env.PORT || 3000;

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const PERENUAL_API_KEY = process.env.PERENUAL_API_KEY;

// GET plants from Supabase
app.get('/plants', async (req, res) => {
  try {
    const { data, error } = await supabase.from('plant').select('*');
    if (error) throw error;
    res.status(200).json(data);
  } catch (err) {
    console.error('Error in /plants:', err.message);
    res.status(500).send('Failed to retrieve plants.');
  }
});

// GET plant details from Perenual by ID
app.get('/api/plants/:id', async (req, res) => {
  const { id } = req.params;
  if (!id || isNaN(id)) return res.status(400).json({ error: "Invalid plant ID" });

  try {
    const url = `https://perenual.com/api/v2/species/details/${id}?key=${PERENUAL_API_KEY}`;
    const response = await fetch(url);
    if (!response.ok) throw new Error("Failed to fetch from Perenual");
    const data = await response.json();
    return res.json(data);
  } catch (err) {
    console.error(`[ERROR] /api/plants/${id}:`, err.message);
    return res.status(500).json({ error: "Failed to fetch plant data" });
  }
});

app.post('/upload', upload.single('file'), async (req, res) => {
  try {
    const file = req.file;
    if (!file) return res.status(400).send('No file uploaded.');

    const filePath = `uploads/${Date.now()}_${file.originalname}`;
    const { error: uploadError } = await supabase.storage
      .from('private-uploads')
      .upload(filePath, file.buffer, { contentType: file.mimetype, upsert: true });

    if (uploadError) return res.status(500).send('Upload to storage failed.');

    const { data: { publicUrl } } = supabase.storage
      .from('private-uploads')
      .getPublicUrl(filePath);

    const { error: dbError } = await supabase
      .from('image')
      .insert([{
        img_name: file.originalname,
        file_path: filePath,
        url: publicUrl,
        date_info: new Date().toISOString()
      }]);

    if (dbError) {
      await supabase.storage.from('private-uploads').remove([filePath]);
      return res.status(500).send('Database insert failed.');
    }

    res.status(200).json({
      success: true,
      fileInfo: { originalName: file.originalname, path: filePath, url: publicUrl }
    });
  } catch (err) {
    res.status(500).send('Server error.');
  }
});

app.get('/retrieve/:image_id', async (req, res) => {
  try {
    const { image_id } = req.params;
    const { data: fileData } = await supabase.from('image').select('file_path, img_name').eq('image_id', image_id).single();
    const decodedPath = decodeURIComponent(fileData.file_path);
    const storagePath = decodedPath.replace(/^https:\/\/.*?\/storage\/v1\/object\/[^\/]+\//, '').trim();
    const { data: fileBlob } = await supabase.storage.from('private-uploads').download(storagePath);
    const arrayBuffer = await fileBlob.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    res.setHeader('Content-Type', 'image/*');
    res.setHeader('Content-Disposition', `attachment; filename="${fileData.img_name}"`);
    res.send(buffer);
  } catch {
    res.status(500).send('Server error.');
  }
});

app.get('/user/:user_id/plants', async (req, res) => {
  try {
    const { user_id } = req.params;
    const { data, error } = await supabase
      .from('user_plants')
      .select(`user_plant_id, date, plant_id (plant_id, 
        common_name, scientific_name, description, image_url, watering, watering_condition,
        pruning, sunlight, growth_stages, tools_needed
      )`)
      .eq('user_id', user_id);

    if (error) {
      throw error;  // Handle Supabase errors
    }

    if (!data || data.length === 0) {
      return res.status(404).send('No plants found for this user.');
    }

    res.status(200).json(data);
  } catch (err) {
    res.status(500).send('Failed to retrieve user plants.');
  }
});

app.get('/user/:user_id/tasks', async (req, res) => {
  try {
    const { user_id } = req.params;
    const { data } = await supabase
      .from('task')
      .select('task_id, title, category, image:image_id (url), user_plant_id')
      .eq('user_id', user_id)
      .order('due_date', { ascending: true });
    res.status(200).json(data);
  } catch {
    res.status(500).send('Failed to retrieve tasks.');
  }
});

app.get('/user/:user_id/full-tasks', async (req, res) => {
  try {
    const { user_id } = req.params;
    const { data } = await supabase
      .from('user_plants')
      .select('user_plant_id, task ( task_id, category, title, image:image_id (url), task_template (template_id, title, description, step_count, steps, image:image_id (url)) )')
      .eq('user_id', user_id);
    res.status(200).json(data);
  } catch {
    res.status(500).send('Failed to retrieve task data.');
  }
});

app.get('/user/:user_id/diaries', async (req, res) => {
  try {
    const { user_id } = req.params;
    const { data, error } = await supabase
      .from('diary')
      .select('diary_id, creation_date, plant:plant_id ( plant_id, name )')
      .eq('user_id', user_id);
    if (error) throw error;
    res.status(200).json(data);
  } catch (err) {
    console.error('Error fetching diaries:', err);
    res.status(500).send('Failed to retrieve user diaries.');
  }
});

app.post('/diary/:diary_id/entry', upload.single('file'), async (req, res) => {
  try {
    const { diary_id } = req.params;
    const { note } = req.body;
    const file = req.file;
    const filePath = `entries/${Date.now()}_${file.originalname}`;
    await supabase.storage.from('private-uploads').upload(filePath, file.buffer, { contentType: file.mimetype, upsert: true });
    const { data: { publicUrl } } = supabase.storage.from('private-uploads').getPublicUrl(filePath);
    const { data: image } = await supabase.from('image').insert([{ img_name: file.originalname, url: publicUrl, signed_key: filePath }]).select().single();
    await supabase.from('diary_entry').insert([{ diary_id, image_id: image.image_id, note }]);
    res.status(200).json({ success: true });
  } catch {
    res.status(500).send('Failed to save diary entry.');
  }
});

app.get('/user/:user_id/diagnoses', async (req, res) => {
  try {
    const { user_id } = req.params;
    const { data } = await supabase
      .from('diagnosis')
      .select('diagnosis_id, plant:plant_id ( name ), image:image_id ( url ), response ( result, description, solution, diagnosis_confidence, diagnosis_date )')
      .eq('user_id', user_id);
    res.status(200).json(data);
  } catch {
    res.status(500).send('Failed to retrieve diagnoses.');
  }
});

app.post('/user/:user_id/plant/:plant_id', async (req, res) => {
  try {
    const { user_id, plant_id } = req.params;
    await supabase.from('user_plants').insert([{ user_id, plant_id, date: new Date().toISOString() }]);
    res.status(201).send('Plant added to user.');
  } catch {
    res.status(500).send('Failed to add plant to user.');
  }
});



//Still Not Fixed, Attempting to use = error
app.post('/diagnose/:image_id', async (req, res) => {
  try {
    const { image_id } = req.params;
    const { data: image } = await supabase.from('image').select('file_path').eq('image_id', image_id).single();
    const { data: fileBlob } = await supabase.storage.from('private-uploads').download(image.file_path);
    const arrayBuffer = await fileBlob.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    const response = await fetch('http://localhost:5000/predict', {
      method: 'POST',
      body: (() => {
        const formData = new FormData();
        formData.append('file', buffer, { filename: 'image.jpg' });
        return formData;
      })()
    });

    if (!response.ok) throw new Error('Prediction service error');
    const prediction = await response.json();
    res.json(prediction);
  } catch (err) {
    console.error('Diagnosis error:', err);
    res.status(500).send('Diagnosis failed');
  }
});


app.listen(PORT, () => {
  console.log(`server running on http://localhost:${PORT}`);
});