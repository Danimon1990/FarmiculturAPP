#!/usr/bin/env node

const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const FARM_ID = "22F24F81-D799-4054-95A4-6EF4AAC790E7";

async function deleteCollection(collectionRef, batchSize = 100) {
  const query = collectionRef.limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(query, resolve).catch(reject);
  });
}

async function deleteQueryBatch(query, resolve) {
  const snapshot = await query.get();

  if (snapshot.size === 0) {
    resolve();
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });
  await batch.commit();

  // Recurse on the next process tick
  process.nextTick(() => {
    deleteQueryBatch(query, resolve);
  });
}

async function deleteAllFarmData() {
  console.log('🗑️  Deleting old farm data...\n');

  const farmRef = db.collection('farms').doc(FARM_ID);

  // Get all crop areas
  const areasSnapshot = await farmRef.collection('cropAreas').get();

  for (const areaDoc of areasSnapshot.docs) {
    console.log(`  Deleting area: ${areaDoc.data().name}`);

    // Get all sections
    const sectionsSnapshot = await areaDoc.ref.collection('sections').get();

    for (const sectionDoc of sectionsSnapshot.docs) {
      console.log(`    Deleting section: ${sectionDoc.data().name}`);

      // Delete all beds in this section
      await deleteCollection(sectionDoc.ref.collection('beds'));

      // Delete the section
      await sectionDoc.ref.delete();
    }

    // Delete the area
    await areaDoc.ref.delete();
  }

  // Delete tasks
  console.log('  Deleting tasks...');
  await deleteCollection(farmRef.collection('tasks'));

  console.log('✅ Cleanup complete!\n');
}

async function main() {
  try {
    await deleteAllFarmData();
    console.log('🔄 Now running populate script...\n');

    // Run the populate script
    const { execSync } = require('child_process');
    execSync(`FARM_ID="${FARM_ID}" node populate-farm-data.js`, { stdio: 'inherit' });

    console.log('\n✅ All done!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

main();
