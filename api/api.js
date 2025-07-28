// import express, { json } from "express";
// import multer, { memoryStorage } from "multer";
// import fetch from "node-fetch";
// import FormData from "form-data";
// import { createClient } from "@supabase/supabase-js";
// import dotenv from "dotenv";
// dotenv.config();

// const app = express();
// const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 2 * 1024 * 1024 } });
// app.use(express.json());

// const PORT = process.env.PORT || 3000;

// const supabase = createClient(
//   process.env.SUPABASE_URL,
//   process.env.SUPABASE_SERVICE_ROLE_KEY
// );

// const PERENUAL_API_KEY = process.env.PERENUAL_API_KEY;

// // GET plants from Supabase
// app.get('/plants', async (req, res) => {
//   try {
//     const { data, error } = await supabase.from('plant').select('*');
//     if (error) throw error;
//     res.status(200).json(data);
//   } catch (err) {
//     console.error('Error in /plants:', err.message);
//     res.status(500).send('Failed to retrieve plants.');
//   }
// });

// // GET plant details from Perenual by ID
// app.get('/api/plants/:id', async (req, res) => {
//   const { id } = req.params;
//   if (!id || isNaN(id)) return res.status(400).json({ error: "Invalid plant ID" });

//   try {
//     const url = `https://perenual.com/api/v2/species/details/${id}?key=${PERENUAL_API_KEY}`;
//     const response = await fetch(url);
//     if (!response.ok) throw new Error("Failed to fetch from Perenual");
//     const data = await response.json();
//     return res.json(data);
//   } catch (err) {
//     console.error(`[ERROR] /api/plants/${id}:`, err.message);
//     return res.status(500).json({ error: "Failed to fetch plant data" });
//   }
// });

// app.post('/upload', upload.single('file'), async (req, res) => {
//   try {
//     const file = req.file;
//     if (!file) return res.status(400).send('No file uploaded.');

//     const filePath = `uploads/${Date.now()}_${file.originalname}`;
//     const { error: uploadError } = await supabase.storage
//       .from('private-uploads')
//       .upload(filePath, file.buffer, { contentType: file.mimetype, upsert: true });

//     if (uploadError) return res.status(500).send('Upload to storage failed.');

//     const { data: { publicUrl } } = supabase.storage
//       .from('private-uploads')
//       .getPublicUrl(filePath);

//     const { error: dbError } = await supabase
//       .from('image')
//       .insert([{
//         img_name: file.originalname,
//         file_path: filePath,
//         url: publicUrl,
//         date_info: new Date().toISOString()
//       }]);

//     if (dbError) {
//       await supabase.storage.from('private-uploads').remove([filePath]);
//       return res.status(500).send('Database insert failed.');
//     }

//     res.status(200).json({
//       success: true,
//       fileInfo: { originalName: file.originalname, path: filePath, url: publicUrl }
//     });
//   } catch (err) {
//     res.status(500).send('Server error.');
//   }
// });

// app.get('/retrieve/:image_id', async (req, res) => {
//   try {
//     const { image_id } = req.params;
//     const { data: fileData } = await supabase.from('image').select('file_path, img_name').eq('image_id', image_id).single();
//     const decodedPath = decodeURIComponent(fileData.file_path);
//     const storagePath = decodedPath.replace(/^https:\/\/.*?\/storage\/v1\/object\/[^\/]+\//, '').trim();
//     const { data: fileBlob } = await supabase.storage.from('private-uploads').download(storagePath);
//     const arrayBuffer = await fileBlob.arrayBuffer();
//     const buffer = Buffer.from(arrayBuffer);
//     res.setHeader('Content-Type', 'image/*');
//     res.setHeader('Content-Disposition', `attachment; filename="${fileData.img_name}"`);
//     res.send(buffer);
//   } catch {
//     res.status(500).send('Server error.');
//   }
// });

// app.get('/user/:user_id/plants', async (req, res) => {
//   try {
//     const { user_id } = req.params;
//     const { data, error } = await supabase
//       .from('user_plants')
//       .select(`user_plant_id, date, plant_id (plant_id, 
//         common_name, scientific_name, description, image_url, watering, watering_condition,
//         pruning, sunlight, growth_stages, tools_needed
//       )`)
//       .eq('user_id', user_id);

//     if (error) {
//       throw error;  // Handle Supabase errors
//     }

//     if (!data || data.length === 0) {
//       return res.status(404).send('No plants found for this user.');
//     }

//     res.status(200).json(data);
//   } catch (err) {
//     res.status(500).send('Failed to retrieve user plants.');
//   }
// });
 

// app.get('/user/:user_id/tasks', async (req, res) => {
//   try {
//     const { user_id } = req.params;
    
//     // First get user's plants
//     const { data: userPlants } = await supabase
//       .from('user_plants')
//       .select('user_plant_id')
//       .eq('user_id', user_id);
    
//     if (!userPlants || userPlants.length === 0) {
//       return res.status(200).json([]);
//     }
    
//     // Then get tasks for those plants
//     const plantIds = userPlants.map(plant => plant.user_plant_id);
//     const { data: tasks } = await supabase
//       .from('task')
//       .select('*')
//       .in('user_plant_id', plantIds)
//       .order('due_date', { ascending: true });
    
//     res.status(200).json(tasks || []);
//   } catch (err) {
//     console.error(err);
//     res.status(500).send('Failed to retrieve tasks.');
//   }
// });

// app.get('/user/:user_id/full-tasks', async (req, res) => {
//   try {
//     const { user_id } = req.params;
//     const { data } = await supabase
//       .from('user_plants')
//       .select('user_plant_id, task ( task_id, category, title, image:image_id (url), task_template (template_id, title, description, step_count, steps, image:image_id (url)) )')
//       .eq('user_id', user_id);
//     res.status(200).json(data);
//   } catch {
//     res.status(500).send('Failed to retrieve task data.');
//   }
// });

// app.get('/user/:user_id/diaries', async (req, res) => {
//   try {
//     const { user_id } = req.params;
//     const { data, error } = await supabase
//       .from('diary')
//       .select('diary_id, creation_date, plant:plant_id ( plant_id, name )')
//       .eq('user_id', user_id);
//     if (error) throw error;
//     res.status(200).json(data);
//   } catch (err) {
//     console.error('Error fetching diaries:', err);
//     res.status(500).send('Failed to retrieve user diaries.');
//   }
// });

// app.post('/diary/:diary_id/entry', upload.single('file'), async (req, res) => {
//   try {
//     const { diary_id } = req.params;
//     const { note } = req.body;
//     const file = req.file;
//     const filePath = `entries/${Date.now()}_${file.originalname}`;
//     await supabase.storage.from('private-uploads').upload(filePath, file.buffer, { contentType: file.mimetype, upsert: true });
//     const { data: { publicUrl } } = supabase.storage.from('private-uploads').getPublicUrl(filePath);
//     const { data: image } = await supabase.from('image').insert([{ img_name: file.originalname, url: publicUrl, signed_key: filePath }]).select().single();
//     await supabase.from('diary_entry').insert([{ diary_id, image_id: image.image_id, note }]);
//     res.status(200).json({ success: true });
//   } catch {
//     res.status(500).send('Failed to save diary entry.');
//   }
// });

// app.get('/user/:user_id/diagnoses', async (req, res) => {
//   try {
//     const { user_id } = req.params;
//     const { data } = await supabase
//       .from('diagnosis')
//       .select('diagnosis_id, plant:plant_id ( name ), image:image_id ( url ), response ( result, description, solution, diagnosis_confidence, diagnosis_date )')
//       .eq('user_id', user_id);
//     res.status(200).json(data);
//   } catch {
//     res.status(500).send('Failed to retrieve diagnoses.');
//   }
// });

// // Alternative: You can also use this shorter version
// function getTodayDateString() {
//   return new Date().toLocaleDateString('en-CA'); // Returns YYYY-MM-DD in local timezone
// }

// app.post('/user/:user_id/plant/:plant_id', async (req, res) => {
//   try {
//     const { user_id, plant_id } = req.params;
    
//     // Get today's date string in YYYY-MM-DD format for date columns
//     const todayDate = getTodayDateString();

//     // 1. Add the plant to the user's garden
//     const { data: userPlant, error: insertError } = await supabase
//       .from('user_plants')
//       .insert({
//         user_id,
//         plant_id,
//         date: todayDate // PostgreSQL date type expects YYYY-MM-DD
//       })
//       .select()
//       .single();

//     if (insertError) throw insertError;

//     // 2. Get the plant to find its associated propagation_template_id
//     const { data: plantData, error: plantError } = await supabase
//       .from('plant')
//       .select('propagation_template_id')
//       .eq('plant_id', plant_id)
//       .single();

//     if (plantError) throw plantError;

//     const templateId = plantData.propagation_template_id;
//     if (!templateId) {
//       return res.status(201).send('Plant added, but no propagation template linked.');
//     }

//     // 3. Fetch the corresponding propagation task template
//     const { data: template, error: templateError } = await supabase
//       .from('task_template')
//       .select('*')
//       .eq('template_id', templateId)
//       .single();

//     if (templateError) throw templateError;

//     const steps = template.steps.filter(step => step && step.trim() !== '');

//     // 4. Create tasks for each step
//     const tasks = steps.map(step => ({
//       user_plant_id: userPlant.user_plant_id,
//       template_id: template.template_id,
//       description: step,
//       due_date: todayDate, // PostgreSQL date type expects YYYY-MM-DD
//       is_completed: false,
//       progress: 'not_started'
//     }));

//     const { error: taskError } = await supabase
//       .from('task')
//       .insert(tasks);

//     if (taskError) throw taskError;

//     res.status(201).send('Plant and propagation tasks added successfully');
//   } catch (err) {
//     console.error(err);
//     res.status(500).send('Failed to add plant and tasks');
//   }
// });

// //Still Not Fixed, Attempting to use = error
// app.post('/diagnose/:image_id', async (req, res) => {
//   try {
//     const { image_id } = req.params;
//     const { data: image } = await supabase.from('image').select('file_path').eq('image_id', image_id).single();
//     const { data: fileBlob } = await supabase.storage.from('private-uploads').download(image.file_path);
//     const arrayBuffer = await fileBlob.arrayBuffer();
//     const buffer = Buffer.from(arrayBuffer);

//     const response = await fetch('http://localhost:5000/predict', {
//       method: 'POST',
//       body: (() => {
//         const formData = new FormData();
//         formData.append('file', buffer, { filename: 'image.jpg' });
//         return formData;
//       })()
//     });

//     if (!response.ok) throw new Error('Prediction service error');
//     const prediction = await response.json();
//     res.json(prediction);
//   } catch (err) {
//     console.error('Diagnosis error:', err);
//     res.status(500).send('Diagnosis failed');
//   }
// });


// app.listen(PORT, () => {
//   console.log(`server running on http://localhost:${PORT}`);
// });




// Add these imports to the top of your existing api.js file
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

// ========================
// TASK AUTOMATION FUNCTIONS
// ========================

/**
 * Check if all propagation tasks for a user plant are complete
 */
async function areAllPropagationTasksComplete(userPlantId) {
  try {
    // Get all propagation tasks for this user plant
    const { data: propagationTasks, error } = await supabase
      .from('task')
      .select(`
        task_id,
        is_completed,
        template_id,
        task_template!inner(category)
      `)
      .eq('user_plant_id', userPlantId)
      .eq('task_template.category', 'Propagation');
    
    if (error) throw error;
    
    if (!propagationTasks || propagationTasks.length === 0) {
      console.log('⚠️ No propagation tasks found');
      return false;
    }
    
    // Check if all are completed
    const allComplete = propagationTasks.every(task => task.is_completed === true);
    
    console.log(`📊 Propagation tasks: ${propagationTasks.length} total, ${propagationTasks.filter(t => t.is_completed).length} completed`);
    
    return allComplete;
    
  } catch (error) {
    console.error('❌ Error checking propagation completion:', error);
    throw error;
  }
}

/**
 * Get the completion date of the last propagation task
 */
async function getLastPropagationCompletionDate(userPlantId) {
  try {
    const { data: lastTask, error } = await supabase
      .from('task')
      .select(`
        date_completed,
        task_template!inner(category)
      `)
      .eq('user_plant_id', userPlantId)
      .eq('task_template.category', 'Propagation')
      .eq('is_completed', true)
      .order('date_completed', { ascending: false })
      .limit(1)
      .single();
    
    if (error) throw error;
    
    return new Date(lastTask.date_completed);
    
  } catch (error) {
    console.error('❌ Error getting last propagation date:', error);
    throw error;
  }
}

/**
 * Get the watering interval for a plant
 */
async function getPlantWateringInterval(userPlantId) {
  try {
    const { data: userPlant, error } = await supabase
      .from('user_plants')
      .select(`
        plant_id!inner(watering)
      `)
      .eq('user_plant_id', userPlantId)
      .single();
    
    if (error) throw error;
    
    const wateringString = userPlant.plant_id.watering; // e.g., "7-10"
    const firstNumber = parseInt(wateringString.split('-')[0]);
    
    console.log(`💧 Watering interval: ${wateringString} -> ${firstNumber} days`);
    
    return firstNumber;
    
  } catch (error) {
    console.error('❌ Error getting watering interval:', error);
    throw error;
  }
}

/**
 * Check if recurring tasks already exist for this plant
 */
async function checkExistingRecurringTasks(userPlantId) {
  try {
    const { data: existingTasks, error } = await supabase
      .from('task')
      .select(`
        task_id,
        task_template!inner(category)
      `)
      .eq('user_plant_id', userPlantId)
      .in('task_template.category', ['Watering', 'Pest Inspection']);
    
    if (error) throw error;
    
    const hasWatering = existingTasks?.some(t => t.task_template.category === 'Watering') || false;
    const hasPestInspection = existingTasks?.some(t => t.task_template.category === 'Pest Inspection') || false;
    
    return { hasWatering, hasPestInspection };
    
  } catch (error) {
    console.error('❌ Error checking existing tasks:', error);
    return { hasWatering: false, hasPestInspection: false };
  }
}

/**
 * Generate watering tasks for the next 2 weeks - Updated to create separate tasks for each step
 */
function generateWateringTasks(userPlantId, template, startDate, intervalDays, endDate) {
  const tasks = [];
  let currentDate = new Date(startDate);
  currentDate.setDate(currentDate.getDate() + intervalDays); // First watering after interval
  
  // Filter out empty steps, just like in the propagation task creation
  const steps = template.steps.filter(step => step && step.trim() !== '');
  
  while (currentDate <= endDate) {
    // Create a separate task for each step in the watering process
    steps.forEach(step => {
      tasks.push({
        user_plant_id: userPlantId,
        template_id: template.template_id,
        progress: 'pending',
        is_completed: false,
        due_date: currentDate.toISOString().split('T')[0], // YYYY-MM-DD format
        description: step, // Use individual step instead of template description
        date_completed: null
      });
    });
    
    // Next watering session
    currentDate = new Date(currentDate);
    currentDate.setDate(currentDate.getDate() + intervalDays);
  }
  
  console.log(`💧 Generated ${tasks.length} watering tasks (${steps.length} steps per session)`);
  return tasks;
}


/**
 * Generate pest inspection tasks for the next 2 weeks
 */
function generatePestInspectionTasks(userPlantId, template, startDate, endDate) {
  const tasks = [];
  let currentDate = new Date(startDate);
  currentDate.setDate(currentDate.getDate() + 14); // First inspection 14 days after propagation
  
  // Filter out empty steps, just like in the propagation task creation
  const steps = template.steps.filter(step => step && step.trim() !== '');
  
  while (currentDate <= endDate) {
    // Create a separate task for each step in the pest inspection process
    steps.forEach(step => {
      tasks.push({
        user_plant_id: userPlantId,
        template_id: template.template_id,
        progress: 'pending',
        is_completed: false,
        due_date: currentDate.toISOString().split('T')[0], // YYYY-MM-DD format
        description: step, // Use individual step instead of template description
        date_completed: null
      });
    });
    
    // Next inspection (every 7 days)
    currentDate = new Date(currentDate);
    currentDate.setDate(currentDate.getDate() + 7);
  }
  
  console.log(`🔍 Generated ${tasks.length} pest inspection tasks (${steps.length} steps per session)`);
  return tasks;
}

/**
 * Schedule recurring watering and pest inspection tasks
 */
async function scheduleRecurringTasks(userPlantId, lastPropagationDate, wateringInterval) {
  try {
    // Get task templates
    const { data: templates, error: templateError } = await supabase
      .from('task_template')
      .select('*')
      .in('category', ['Watering', 'Pest Inspection']);
    
    if (templateError) throw templateError;
    
    const wateringTemplate = templates.find(t => t.category === 'Watering');
    const pestTemplate = templates.find(t => t.category === 'Pest Inspection');
    
    if (!wateringTemplate || !pestTemplate) {
      throw new Error('Required task templates not found');
    }
    
    // Check if recurring tasks already exist to avoid duplicates
    const existingTasks = await checkExistingRecurringTasks(userPlantId);
    
    const tasksToInsert = [];
    const currentDate = new Date();
    const twoWeeksFromNow = new Date(currentDate.getTime() + (14 * 24 * 60 * 60 * 1000));
    
    // Schedule Watering Tasks (starting from day after last propagation)
    if (!existingTasks.hasWatering) {
      const wateringTasks = generateWateringTasks(
        userPlantId,
        wateringTemplate,
        lastPropagationDate,
        wateringInterval,
        twoWeeksFromNow
      );
      tasksToInsert.push(...wateringTasks);
    }
    
    // Schedule Pest Inspection Tasks (starting 14 days after last propagation)
    if (!existingTasks.hasPestInspection) {
      const pestTasks = generatePestInspectionTasks(
        userPlantId,
        pestTemplate,
        lastPropagationDate,
        twoWeeksFromNow
      );
      tasksToInsert.push(...pestTasks);
    }
    
    // Insert all tasks
    if (tasksToInsert.length > 0) {
      const { error: insertError } = await supabase
        .from('task')
        .insert(tasksToInsert);
      
      if (insertError) throw insertError;
      
      console.log(`✅ Scheduled ${tasksToInsert.length} recurring tasks`);
    }
    
  } catch (error) {
    console.error('❌ Error scheduling recurring tasks:', error);
    throw error;
  }
}

/**
 * Main function to check if all propagation tasks are complete
 * and schedule recurring tasks if needed
 */
async function checkAndScheduleRecurringTasks(userPlantId) {
  try {
    console.log(`🔍 Checking propagation completion for user_plant_id: ${userPlantId}`);
    
    // 1. Check if all propagation tasks are complete
    const allPropagationComplete = await areAllPropagationTasksComplete(userPlantId);
    
    if (!allPropagationComplete) {
      console.log('❌ Not all propagation tasks are complete yet');
      return { success: true, message: 'Propagation still in progress' };
    }
    
    console.log('✅ All propagation tasks complete! Starting recurring task setup...');
    
    // 2. Get the completion date of the last propagation task
    const lastPropagationDate = await getLastPropagationCompletionDate(userPlantId);
    
    if (!lastPropagationDate) {
      throw new Error('Could not find last propagation completion date');
    }
    
    // 3. Get plant watering interval
    const wateringInterval = await getPlantWateringInterval(userPlantId);
    
    // 4. Schedule watering and pest inspection tasks
    await scheduleRecurringTasks(userPlantId, lastPropagationDate, wateringInterval);
    
    return { 
      success: true, 
      message: 'Recurring tasks scheduled successfully',
      lastPropagationDate,
      wateringInterval
    };
    
  } catch (error) {
    console.error('❌ Error in checkAndScheduleRecurringTasks:', error);
    throw error;
  }
}

/**
 * Function to extend recurring tasks (call this every 2 weeks or when needed)
 */
async function extendRecurringTasks(userPlantId) {
  try {
    console.log(`🔄 Extending recurring tasks for user_plant_id: ${userPlantId}`);
    
    // Check if propagation is complete first
    const allPropagationComplete = await areAllPropagationTasksComplete(userPlantId);
    if (!allPropagationComplete) {
      return { success: false, message: 'Propagation not yet complete' };
    }
    
    // Get the latest existing task dates
    const { data: latestTasks, error } = await supabase
      .from('task')
      .select(`
        due_date,
        task_template!inner(category)
      `)
      .eq('user_plant_id', userPlantId)
      .in('task_template.category', ['Watering', 'Pest Inspection'])
      .order('due_date', { ascending: false })
      .limit(2);
    
    if (error) throw error;
    
    const latestWatering = latestTasks.find(t => t.task_template.category === 'Watering');
    const latestPestInspection = latestTasks.find(t => t.task_template.category === 'Pest Inspection');
    
    if (!latestWatering && !latestPestInspection) {
      // No existing recurring tasks, might need to start them
      return await checkAndScheduleRecurringTasks(userPlantId);
    }
    
    const wateringInterval = await getPlantWateringInterval(userPlantId);
    
    // Get templates
    const { data: templates, error: templateError } = await supabase
      .from('task_template')
      .select('*')
      .in('category', ['Watering', 'Pest Inspection']);
    
    if (templateError) throw templateError;
    
    const tasksToInsert = [];
    const twoWeeksFromNow = new Date();
    twoWeeksFromNow.setDate(twoWeeksFromNow.getDate() + 14);
    
    // Extend watering tasks
    if (latestWatering) {
      const nextWateringDate = new Date(latestWatering.due_date);
      nextWateringDate.setDate(nextWateringDate.getDate() + wateringInterval);
      
      const wateringTemplate = templates.find(t => t.category === 'Watering');
      const wateringSteps = wateringTemplate.steps.filter(step => step && step.trim() !== '');
      
      while (nextWateringDate <= twoWeeksFromNow) {
        // Create separate tasks for each watering step
        wateringSteps.forEach(step => {
          tasksToInsert.push({
            user_plant_id: userPlantId,
            template_id: wateringTemplate.template_id,
            progress: 'pending',
            is_completed: false,
            due_date: nextWateringDate.toISOString().split('T')[0],
            description: step, // Individual step instead of template description
            date_completed: null
          });
        });
        
        nextWateringDate.setDate(nextWateringDate.getDate() + wateringInterval);
      }
    }
    
    // Extend pest inspection tasks
    if (latestPestInspection) {
      const nextInspectionDate = new Date(latestPestInspection.due_date);
      nextInspectionDate.setDate(nextInspectionDate.getDate() + 7);
      
      const pestTemplate = templates.find(t => t.category === 'Pest Inspection');
      const pestSteps = pestTemplate.steps.filter(step => step && step.trim() !== '');
      
      while (nextInspectionDate <= twoWeeksFromNow) {
        // Create separate tasks for each pest inspection step
        pestSteps.forEach(step => {
          tasksToInsert.push({
            user_plant_id: userPlantId,
            template_id: pestTemplate.template_id,
            progress: 'pending',
            is_completed: false,
            due_date: nextInspectionDate.toISOString().split('T')[0],
            description: step, // Individual step instead of template description
            date_completed: null
          });
        });
        
        nextInspectionDate.setDate(nextInspectionDate.getDate() + 7);
      }
    }
    
    // Insert new tasks
    if (tasksToInsert.length > 0) {
      const { error: insertError } = await supabase
        .from('task')
        .insert(tasksToInsert);
      
      if (insertError) throw insertError;
      
      console.log(`✅ Extended ${tasksToInsert.length} recurring tasks`);
    }
    
    return { success: true, message: `Extended ${tasksToInsert.length} tasks` };
    
  } catch (error) {
    console.error('❌ Error extending recurring tasks:', error);
    throw error;
  }
}

// ========================
// EXISTING ROUTES (keep all your existing routes here)
// ========================

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

// ... (keep all your other existing routes)

// app.get('/plants', async (req, res) => {
//   try {
//     const { data, error } = await supabase.from('plant').select('*');
//     if (error) throw error;
//     res.status(200).json(data);
//   } catch (err) {
//     console.error('Error in /plants:', err.message);
//     res.status(500).send('Failed to retrieve plants.');
//   }
// });

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
    
    // First get user's plants
    const { data: userPlants } = await supabase
      .from('user_plants')
      .select('user_plant_id')
      .eq('user_id', user_id);
    
    if (!userPlants || userPlants.length === 0) {
      return res.status(200).json([]);
    }
    
    // Then get tasks for those plants
    const plantIds = userPlants.map(plant => plant.user_plant_id);
    const { data: tasks } = await supabase
      .from('task')
      .select('*')
      .in('user_plant_id', plantIds)
      .order('due_date', { ascending: true });
    
    res.status(200).json(tasks || []);
  } catch (err) {
    console.error(err);
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

// ========================
// UPDATED TASK ROUTES
// ========================

// Updated task fetching to include only next 2 weeks
app.get('/user/:user_id/tasks', async (req, res) => {
  try {
    const { user_id } = req.params;
    
    // Calculate date range (today + 2 weeks)
    const now = new Date();
    const today = now.toISOString().split('T')[0];
    const twoWeeksFromNow = new Date(now.getTime() + (14 * 24 * 60 * 60 * 1000))
      .toISOString().split('T')[0];
    
    // First get user's plants
    const { data: userPlants } = await supabase
      .from('user_plants')
      .select('user_plant_id')
      .eq('user_id', user_id);
    
    if (!userPlants || userPlants.length === 0) {
      return res.status(200).json([]);
    }
    
    // Then get tasks for those plants within date range
    const plantIds = userPlants.map(plant => plant.user_plant_id);
    const { data: tasks } = await supabase
      .from('task')
      .select('*')
      .in('user_plant_id', plantIds)
      .gte('due_date', today)
      .lte('due_date', twoWeeksFromNow)
      .order('due_date', { ascending: true });
    
    res.status(200).json(tasks || []);
  } catch (err) {
    console.error(err);
    res.status(500).send('Failed to retrieve tasks.');
  }
});

// Updated task completion endpoint with recurring task trigger
app.put('/task/:task_id/complete', async (req, res) => {
  try {
    const { task_id } = req.params;
    const { is_completed } = req.body;
    
    // Get task details including category
    const { data: taskData, error: fetchError } = await supabase
      .from('task')
      .select(`
        task_id,
        user_plant_id,
        due_date,
        is_completed,
        task_template!inner(category)
      `)
      .eq('task_id', task_id)
      .single();
    
    if (fetchError) throw fetchError;
    
    const dueDate = new Date(taskData.due_date);
    const category = taskData.task_template.category;
    const userPlantId = taskData.user_plant_id;
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const taskDate = new Date(dueDate.getFullYear(), dueDate.getMonth(), dueDate.getDate());

    let progress;
    let finalIsCompleted;

    if (is_completed) {
      progress = 'completed';
      finalIsCompleted = true;
    } else {
      if (taskDate < today) {
        progress = 'overdue';
        finalIsCompleted = false;
      } else {
        progress = 'started';
        finalIsCompleted = false;
      }
    }

    // Update the task
    const { error: updateError } = await supabase
      .from('task')
      .update({
        progress: progress,
        is_completed: finalIsCompleted,
        date_completed: is_completed ? 
          new Date().toISOString().split('T')[0] : null,
      })
      .eq('task_id', task_id);

    if (updateError) throw updateError;

    // If this was a propagation task being completed, check if recurring tasks should start
    if (is_completed && category === 'Propagation') {
      console.log('🌱 Propagation task completed, checking if recurring tasks should start...');
      try {
        await checkAndScheduleRecurringTasks(userPlantId);
      } catch (recurringError) {
        console.error('⚠️ Error setting up recurring tasks:', recurringError);
        // Don't fail the main request - task completion succeeded
      }
    }

    res.status(200).json({ 
      success: true, 
      message: 'Task updated successfully',
      task_id: task_id,
      is_completed: finalIsCompleted,
      progress: progress
    });

  } catch (err) {
    console.error('Error updating task:', err);
    res.status(500).send('Failed to update task.');
  }
});

// ========================
// NEW TASK AUTOMATION API ROUTES
// ========================

// Check and schedule recurring tasks
app.post('/api/check-and-schedule-tasks', async (req, res) => {
  try {
    const { user_plant_id } = req.body;
    
    if (!user_plant_id) {
      return res.status(400).json({
        success: false,
        error: 'user_plant_id is required'
      });
    }

    console.log(`📝 Checking and scheduling tasks for user_plant_id: ${user_plant_id}`);
    
    const result = await checkAndScheduleRecurringTasks(user_plant_id);
    
    res.json(result);
    
  } catch (error) {
    console.error('❌ Error in check-and-schedule-tasks route:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Extend recurring tasks
app.post('/api/extend-recurring-tasks', async (req, res) => {
  try {
    const { user_plant_id } = req.body;
    
    if (!user_plant_id) {
      return res.status(400).json({
        success: false,
        error: 'user_plant_id is required'
      });
    }

    console.log(`🔄 Extending recurring tasks for user_plant_id: ${user_plant_id}`);
    
    const result = await extendRecurringTasks(user_plant_id);
    
    res.json(result);
    
  } catch (error) {
    console.error('❌ Error in extend-recurring-tasks route:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Check propagation status
app.get('/api/user-plant/:userPlantId/propagation-status', async (req, res) => {
  try {
    const { userPlantId } = req.params;
    
    if (!userPlantId) {
      return res.status(400).json({
        success: false,
        error: 'userPlantId is required'
      });
    }

    const allComplete = await areAllPropagationTasksComplete(parseInt(userPlantId));
    
    res.json({
      success: true,
      propagation_complete: allComplete,
      user_plant_id: parseInt(userPlantId)
    });
    
  } catch (error) {
    console.error('❌ Error checking propagation status:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Helper function to get today's date in YYYY-MM-DD format for PostgreSQL date type
function getTodayDateString() {
  return new Date().toLocaleDateString('en-CA'); // Returns YYYY-MM-DD in local timezone
}

// Keep your existing plant addition route (it's already working well)
app.post('/user/:user_id/plant/:plant_id', async (req, res) => {
  try {
    const { user_id, plant_id } = req.params;
    
    const todayDate = getTodayDateString();

    const { data: userPlant, error: insertError } = await supabase
      .from('user_plants')
      .insert({
        user_id,
        plant_id,
        date: todayDate
      })
      .select()
      .single();

    if (insertError) throw insertError;

    const { data: plantData, error: plantError } = await supabase
      .from('plant')
      .select('propagation_template_id')
      .eq('plant_id', plant_id)
      .single();

    if (plantError) throw plantError;

    const templateId = plantData.propagation_template_id;
    if (!templateId) {
      return res.status(201).send('Plant added, but no propagation template linked.');
    }

    const { data: template, error: templateError } = await supabase
      .from('task_template')
      .select('*')
      .eq('template_id', templateId)
      .single();

    if (templateError) throw templateError;

    const steps = template.steps.filter(step => step && step.trim() !== '');

    const tasks = steps.map(step => ({
      user_plant_id: userPlant.user_plant_id,
      template_id: template.template_id,
      description: step,
      due_date: todayDate,
      is_completed: false,
      progress: 'not_started'
    }));

    const { error: taskError } = await supabase
      .from('task')
      .insert(tasks);

    if (taskError) throw taskError;

    res.status(201).json({
      success: true,
      message: 'Plant and propagation tasks added successfully',
      user_plant_id: userPlant.user_plant_id,
      tasks_created: tasks.length
    });
  } catch (err) {
    console.error(err);
    res.status(500).send('Failed to add plant and tasks');
  }
});

// ... (keep all your other existing routes like upload, retrieve, diagnose, etc.)


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