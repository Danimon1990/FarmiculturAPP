#!/usr/bin/env node

/**
 * Firebase Data Population Script
 *
 * This script populates your Firebase with sample farm data including:
 * - Crop Areas (Greenhouses, Outdoor Beds, etc.)
 * - Sections within each area
 * - Beds within each section
 * - Sample tasks
 *
 * Usage:
 *   1. npm install firebase-admin
 *   2. Set your FARM_ID environment variable
 *   3. node populate-farm-data.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
// You'll need to download your service account key from Firebase Console
// Go to Project Settings > Service Accounts > Generate New Private Key
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Get farmId from environment or use a default
const FARM_ID = process.env.FARM_ID || 'your-farm-id-here';

console.log(`🌾 Populating data for farm: ${FARM_ID}\n`);

// Sample data structure - YOUR ACTUAL FARM DATA
const farmData = {
  cropAreas: [
    {
      name: "Cedar",
      type: "greenhouse",
      dimensions: null,
      notes: "Herbs and peppers production area",
      sections: [
        {
          name: "Section 1",
          sectionNumber: "1",
          beds: [
            { bedNumber: "1-1", status: "growing", cropName: "Basil", varieties: ["Genovese"], plantCount: 30 },
            { bedNumber: "1-2", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "1-3", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "1-4", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "1-5", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "1-6", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "1-7", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "1-8", status: "growing", cropName: "Rosemary", varieties: ["Common Rosemary"], plantCount: 30 }
          ]
        },
        {
          name: "Section 2",
          sectionNumber: "2",
          beds: [
            { bedNumber: "2-1", status: "growing", cropName: "Celery", varieties: ["Golden Self-Blanching"], plantCount: 30 },
            { bedNumber: "2-2", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "2-3", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "2-4", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "2-5", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "2-6", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "2-7", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "2-8", status: "growing", cropName: "Chives", varieties: ["Common Chives"], plantCount: 30 }
          ]
        }
      ]
    },
    {
      name: "Trees",
      type: "greenhouse",
      dimensions: null,
      notes: "Carrot production greenhouse",
      sections: [
        {
          name: "Section 1",
          sectionNumber: "1",
          beds: [
            { bedNumber: "1-1", status: "growing", cropName: "Carrots", varieties: ["Nantes"], plantCount: 30 },
            { bedNumber: "1-2", status: "growing", cropName: "Carrots", varieties: ["Nantes"], plantCount: 30 },
            { bedNumber: "1-3", status: "growing", cropName: "Carrots", varieties: ["Nantes"], plantCount: 30 },
            { bedNumber: "1-4", status: "growing", cropName: "Carrots", varieties: ["Nantes"], plantCount: 30 },
            { bedNumber: "1-5", status: "growing", cropName: "Carrots", varieties: ["Nantes"], plantCount: 30 },
            { bedNumber: "1-6", status: "growing", cropName: "Carrots", varieties: ["Nantes"], plantCount: 30 },
            { bedNumber: "1-7", status: "growing", cropName: "Carrots", varieties: ["Nantes"], plantCount: 30 },
            { bedNumber: "1-8", status: "growing", cropName: "Carrots", varieties: ["Nantes"], plantCount: 30 }
          ]
        }
      ]
    },
    {
      name: "Big Cooler",
      type: "greenhouse",
      dimensions: null,
      notes: "Leafy greens and cool season crops",
      sections: [
        {
          name: "Section 1",
          sectionNumber: "1",
          beds: [
            { bedNumber: "1-1", status: "growing", cropName: "Spinach", varieties: ["Bloomsdale"], plantCount: 30 },
            { bedNumber: "1-2", status: "growing", cropName: "Lettuce", varieties: ["Buttercrunch"], plantCount: 30 },
            { bedNumber: "1-3", status: "growing", cropName: "Radish", varieties: ["Cherry Belle"], plantCount: 30 },
            { bedNumber: "1-4", status: "growing", cropName: "Kale", varieties: ["Lacinato"], plantCount: 30 },
            { bedNumber: "1-5", status: "growing", cropName: "Pak Choi", varieties: ["Joi Choi"], plantCount: 30 },
            { bedNumber: "1-6", status: "growing", cropName: "Spinach", varieties: ["Bloomsdale"], plantCount: 30 },
            { bedNumber: "1-7", status: "growing", cropName: "Lettuce", varieties: ["Red Oak"], plantCount: 30 },
            { bedNumber: "1-8", status: "growing", cropName: "Kale", varieties: ["Red Russian"], plantCount: 30 }
          ]
        },
        {
          name: "Section 2",
          sectionNumber: "2",
          beds: [
            { bedNumber: "2-1", status: "growing", cropName: "Lettuce", varieties: ["Green Leaf"], plantCount: 30 },
            { bedNumber: "2-2", status: "growing", cropName: "Spinach", varieties: ["Space"], plantCount: 30 },
            { bedNumber: "2-3", status: "growing", cropName: "Radish", varieties: ["French Breakfast"], plantCount: 30 },
            { bedNumber: "2-4", status: "growing", cropName: "Pak Choi", varieties: ["Toy Choi"], plantCount: 30 },
            { bedNumber: "2-5", status: "growing", cropName: "Kale", varieties: ["Winterbor"], plantCount: 30 },
            { bedNumber: "2-6", status: "growing", cropName: "Lettuce", varieties: ["Romaine"], plantCount: 30 },
            { bedNumber: "2-7", status: "growing", cropName: "Spinach", varieties: ["Tyee"], plantCount: 30 },
            { bedNumber: "2-8", status: "growing", cropName: "Radish", varieties: ["Watermelon"], plantCount: 30 }
          ]
        }
      ]
    },
    {
      name: "Pond",
      type: "greenhouse",
      dimensions: null,
      notes: "Pepper production greenhouse",
      sections: [
        {
          name: "Section 1",
          sectionNumber: "1",
          beds: [
            { bedNumber: "1-1", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "1-2", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "1-3", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "1-4", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "1-5", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "1-6", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "1-7", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 },
            { bedNumber: "1-8", status: "growing", cropName: "Peppers", varieties: ["Bell Pepper"], plantCount: 30 }
          ]
        }
      ]
    }
  ],
  tasks: [
    {
      title: "Clean the beds around the cedar house",
      description: "Remove old plant material and prepare for next planting",
      priority: "high",
      dueDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000), // 2 days from now
      isCompleted: false
    },
    {
      title: "Pick up the sand bags",
      description: "Move sandbags from storage to greenhouse entrance",
      priority: "medium",
      dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // 3 days from now
      isCompleted: false
    },
    {
      title: "Start the basil seeds",
      description: "Sow basil seeds in seed trays for spring planting",
      priority: "high",
      dueDate: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000), // Tomorrow
      isCompleted: false
    },
    {
      title: "Fertilize tomatoes in Greenhouse 1",
      description: "Apply organic fertilizer to all tomato beds",
      priority: "medium",
      dueDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000), // 5 days from now
      isCompleted: false
    },
    {
      title: "Check irrigation system",
      description: "Inspect all drip lines and emitters for clogs",
      priority: "high",
      dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 1 week from now
      isCompleted: false
    }
  ]
};

// Helper function to generate UUIDs
function generateId() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

// Helper to create plant varieties
function createPlantVarieties(varietyNames, cropName, plantCount = 30) {
  return varietyNames.map(name => ({
    id: generateId(),
    name: name,
    count: plantCount,
    daysToMaturity: cropName ? getMaturityDays(cropName) : null,
    continuousHarvest: isMultiHarvestCrop(cropName),
    harvestWindowDays: isMultiHarvestCrop(cropName) ? 45 : null,
    notes: ""
  }));
}

// Helper to get typical maturity days
function getMaturityDays(cropName) {
  const maturityMap = {
    "Basil": 60,
    "Peppers": 75,
    "Rosemary": 120,
    "Celery": 85,
    "Chives": 90,
    "Carrots": 70,
    "Spinach": 45,
    "Lettuce": 45,
    "Radish": 30,
    "Kale": 55,
    "Pak Choi": 50
  };
  return maturityMap[cropName] || 60;
}

// Helper to determine if crop has continuous harvest
function isMultiHarvestCrop(cropName) {
  const multiHarvestCrops = ["Peppers", "Basil", "Rosemary", "Chives", "Lettuce", "Spinach", "Kale"];
  return multiHarvestCrops.includes(cropName);
}

// Main population function
async function populateData() {
  const batch = db.batch();
  const farmRef = db.collection('farms').doc(FARM_ID);

  console.log('📋 Creating crop areas, sections, and beds...\n');

  // Create crop areas with sections and beds
  for (const areaData of farmData.cropAreas) {
    const areaId = generateId();
    const areaRef = farmRef.collection('cropAreas').doc(areaId);

    // Create crop area
    batch.set(areaRef, {
      id: areaId,
      farmId: FARM_ID,
      name: areaData.name,
      type: areaData.type,
      createdDate: admin.firestore.Timestamp.now(),
      dimensions: areaData.dimensions || null,
      notes: areaData.notes || null
    });

    console.log(`  ✅ ${areaData.name} (${areaData.type})`);

    // Create sections
    for (const sectionData of areaData.sections) {
      const sectionId = generateId();
      const sectionRef = areaRef.collection('sections').doc(sectionId);

      batch.set(sectionRef, {
        id: sectionId,
        cropAreaId: areaId,
        name: sectionData.name,
        sectionNumber: sectionData.sectionNumber || null,
        createdDate: admin.firestore.Timestamp.now(),
        dimensions: null,
        notes: null
      });

      console.log(`    ↳ Section: ${sectionData.name}`);

      // Create beds
      for (const bedData of sectionData.beds) {
        const bedId = generateId();
        const bedRef = sectionRef.collection('beds').doc(bedId);

        const varieties = bedData.varieties.length > 0
          ? createPlantVarieties(bedData.varieties, bedData.cropName, bedData.plantCount || 30)
          : [];

        const datePlanted = ['planted', 'growing', 'harvesting'].includes(bedData.status)
          ? admin.firestore.Timestamp.fromDate(new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000)) // Random date in last 30 days
          : null;

        const expectedHarvestStart = bedData.cropName && datePlanted
          ? admin.firestore.Timestamp.fromDate(new Date(datePlanted.toDate().getTime() + getMaturityDays(bedData.cropName) * 24 * 60 * 60 * 1000))
          : null;

        batch.set(bedRef, {
          id: bedId,
          sectionId: sectionId,
          cropAreaId: areaId,
          bedNumber: bedData.bedNumber,
          createdDate: admin.firestore.Timestamp.now(),
          status: bedData.status,
          statusHistory: [{
            id: generateId(),
            fromStatus: null,
            toStatus: bedData.status,
            date: admin.firestore.Timestamp.now(),
            changedBy: null,
            notes: "Initial status"
          }],
          availabilityStatus: bedData.status === 'clean' || bedData.status === 'prepared' ? 'available' : 'occupied',
          availableFrom: null,
          lastCropName: null,
          soilRestDays: null,
          startMethod: varieties.length > 0 ? "transplanted" : null,
          datePlanted: datePlanted,
          varieties: varieties,
          expectedHarvestStart: expectedHarvestStart,
          expectedHarvestEnd: expectedHarvestStart ? admin.firestore.Timestamp.fromDate(
            new Date(expectedHarvestStart.toDate().getTime() + (isMultiHarvestCrop(bedData.cropName) ? 45 : 7) * 24 * 60 * 60 * 1000)
          ) : null,
          harvestReports: [],
          notes: null,
          currentCropName: bedData.cropName || null
        });

        console.log(`      → Bed ${bedData.bedNumber}: ${bedData.status}${bedData.cropName ? ' - ' + bedData.cropName : ''}`);
      }
    }
    console.log('');
  }

  // Create tasks
  console.log('📝 Creating tasks...\n');
  for (const taskData of farmData.tasks) {
    const taskId = generateId();
    const taskRef = farmRef.collection('tasks').doc(taskId);

    batch.set(taskRef, {
      id: taskId,
      farmId: FARM_ID,
      title: taskData.title,
      description: taskData.description || "",
      priority: taskData.priority,
      dueDate: admin.firestore.Timestamp.fromDate(taskData.dueDate),
      isCompleted: taskData.isCompleted,
      createdDate: admin.firestore.Timestamp.now(),
      assignedTo: null,
      bedId: null,
      completedDate: null,
      estimatedHours: null,
      actualHours: null,
      subtasks: [],
      activityLog: []
    });

    console.log(`  ✅ ${taskData.title} (${taskData.priority} priority)`);
  }

  // Commit the batch
  console.log('\n🔄 Committing to Firebase...');
  await batch.commit();
  console.log('✨ Done! Your farm data has been populated.\n');

  console.log('📊 Summary:');
  console.log(`  - ${farmData.cropAreas.length} crop areas`);
  console.log(`  - ${farmData.cropAreas.reduce((sum, area) => sum + area.sections.length, 0)} sections`);
  console.log(`  - ${farmData.cropAreas.reduce((sum, area) =>
    sum + area.sections.reduce((sSum, section) => sSum + section.beds.length, 0), 0)} beds`);
  console.log(`  - ${farmData.tasks.length} tasks`);
  console.log('\n🌾 Your farm is ready to go!');
}

// Run the script
populateData()
  .then(() => {
    console.log('\n✅ Script completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Error populating data:', error);
    process.exit(1);
  });
