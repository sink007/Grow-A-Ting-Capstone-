const express = require('express');
const multer = require('multer');
const { createClient } = require('@supabase/supabase-js');
const fetch = require('node-fetch');

const app = express();
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 2 * 1024 * 1024 }
});

const supabase = createClient(
  'https://inecwqviffivqqeesero.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImluZWN3cXZpZmZpdnFxZWVzZXJvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTY4NDc5MCwiZXhwIjoyMDY1MjYwNzkwfQ.YbBVaceMupbyB3XExx6Z6H7ae4txC0yOMrZ9xNiMmcA'
);

app.post('/upload', upload.single('file'), async (req, res) => {
  try {
    const file = req.file;
    if (!file) return res.status(400).send('No file uploaded.');

    const filePath = `uploads/${Date.now()}_${file.originalname}`;
    const { error: uploadError } = await supabase.storage
      .from('private-uploads')
      .upload(filePath, file.buffer, {
        contentType: file.mimetype,
        upsert: true
      });

    if (uploadError) {
      console.error('Storage upload error:', uploadError);
      return res.status(500).send('Upload to storage failed.');
    }

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
      console.error('Database error:', dbError);
      await supabase.storage
        .from('private-uploads')
        .remove([filePath]);
      return res.status(500).send('Database insert failed.');
    }

    res.status(200).json({
      success: true,
      message: 'File uploaded and metadata saved',
      fileInfo: {
        originalName: file.originalname,
        path: filePath,
        url: publicUrl,
      }
    });

  } catch (err) {
    console.error('Server error:', err);
    res.status(500).send('Server error.');
  }
});

app.get('/retrieve/:image_id', async (req, res) => {
  try {
    const { image_id } = req.params;

    const { data: fileData, error: dbError } = await supabase
      .from('image')
      .select('file_path, img_name')
      .eq('image_id', image_id)
      .single();

    if (dbError || !fileData) {
      return res.status(404).send('Image not found in database.');
    }

    const decodedPath = decodeURIComponent(fileData.file_path);
    const storagePath = decodedPath.replace(
      /^https:\/\/.*?\/storage\/v1\/object\/[^\/]+\//, 
      ''
    ).trim();

    const { data: fileBlob, error: downloadError } = await supabase.storage
      .from('private-uploads')
      .download(storagePath);

    if (downloadError) {
      console.error('Storage error:', { pathAttempted: storagePath, error: downloadError });
      return res.status(404).send('File not found in storage.');
    }

    const arrayBuffer = await fileBlob.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    res.setHeader('Content-Type', 'image/*');
    res.setHeader('Content-Disposition', `attachment; filename="${fileData.img_name}"`);
    res.send(buffer);

  } catch (err) {
    console.error('Server error:', err);
    res.status(500).send('Server error.');
  }
});

app.get('/plants', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('plant')
      .select('*');

    if (error) throw error;

    res.status(200).json(data);
  } catch (err) {
    console.error('Error fetching plants:', err);
    res.status(500).send('Failed to retrieve plants.');
  }
});


app.get('/user/:user_id/plants', async (req, res) => {
  try {
    const { user_id } = req.params;

    const { data, error } = await supabase
      .from('user_plants')
      .select(`
        user_plant_id,
        date,
        plant:plant_id (
          plant_id,
          name,
          description,
          image_id
        )
      `)
      .eq('user_id', user_id);

    if (error) throw error;

    res.status(200).json(data);
  } catch (err) {
    console.error('Error fetching user plants:', err);
    res.status(500).send('Failed to retrieve user plants.');
  }
});


app.get('/user/:user_id/tasks', async (req, res) => {
  try {
    const { user_id } = req.params;

    const { data, error } = await supabase
      .from('task')
      .select(`
        task_id,
        task_title,
        description,
        due_date,
        task_completed,
        completion_date,
        plant:plant_id (
          name
        )
      `)
      .eq('user_id', user_id)
      .order('due_date', { ascending: true });

    if (error) throw error;

    res.status(200).json(data);
  } catch (err) {
    console.error('Error fetching user tasks:', err);
    res.status(500).send('Failed to retrieve tasks.');
  }
});


app.get('/user/:user_id/diaries', async (req, res) => {
  try {
    const { user_id } = req.params;

    const { data, error } = await supabase
      .from('diary')
      .select(`
        diary_id,
        creation_date,
        plant:plant_id (
          plant_id,
          name
        )
      `)
      .eq('user_id', user_id);

    if (error) throw error;

    res.status(200).json(data);
  } catch (err) {
    console.error('Error fetching diaries:', err);
    res.status(500).send('Failed to retrieve user diaries.');
  }
});


app.get('/diary/:diary_id/entries', async (req, res) => {
  try {
    const { diary_id } = req.params;

    const { data, error } = await supabase
      .from('diary_entry')
      .select(`
        entry_id,
        entry_date,
        note,
        image:image_id (
          image_id,
          img_name,
          url
        )
      `)
      .eq('diary_id', diary_id)
      .order('entry_date', { ascending: false });

    if (error) throw error;

    res.status(200).json(data);
  } catch (err) {
    console.error('Error fetching diary entries:', err);
    res.status(500).send('Failed to retrieve diary entries.');
  }
});



//Still being worked on

app.post('/diagnose/:image_id', async (req, res) => {
  try {
    const { image_id } = req.params;
    const { data: image, error: dbError } = await supabase
      .from('image')
      .select('file_path')
      .eq('image_id', image_id)
      .single();
    if (dbError) throw dbError;

    const { data: fileBlob, error: downloadError } = await supabase.storage
      .from('private-uploads')
      .download(image.file_path);
    if (downloadError) {
      console.error('Storage error:', downloadError);
      return res.status(404).send('File not found in storage.');
    }

    const arrayBuffer = await fileBlob.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    const response = await fetch('http://localhost:5000/predict', {
      method: 'POST',
      body: (() => {
        const formData = new (require('form-data'))();
        formData.append('file', buffer, { filename: 'image.jpg' });
        return formData;
      })()
    });

    if (!response.ok) {
      throw new Error('Prediction service error');
    }

    const prediction = await response.json();

    res.json(prediction);

  } catch (err) {
    console.error('Diagnosis error:', err);
    res.status(500).send('Diagnosis failed');
  }
});


app.listen(3000, () => console.log('Server running on port 3000'));
