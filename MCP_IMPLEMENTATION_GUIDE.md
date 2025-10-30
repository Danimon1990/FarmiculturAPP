# MCP Implementation Guide for FarmiculturAPP

## Complete Step-by-Step Plan

This guide will walk you through building a complete MCP (Model Context Protocol) integration for your farm management app, including a Swift MCP client and Node.js MCP server.

---

## ✅ Phase 1: Data Structure (COMPLETED)

### What We Did:
- ✅ Added `AvailabilityStatus` enum to track bed availability
- ✅ Added availability fields to `Bed` struct
- ✅ Created `WorkerProfile` for performance tracking
- ✅ Created `CropStats` for crop analytics
- ✅ Created `HarvestForecast` for planning
- ✅ Created `ProductionPlan` for seasonal planning
- ✅ Enhanced `BedTask` with subtasks, activity log, and recurring schedules
- ✅ Verified build succeeds

---

## 🔄 Phase 2: Update FarmDataService (IN PROGRESS)

### Goal:
Add CRUD methods for all new data models to `FarmDataService.swift`

### Steps:

#### 2.1: Add WorkerProfile Methods

Add these methods to `FarmDataService.swift`:

```swift
// MARK: - Worker Profiles

func saveWorkerProfile(_ profile: WorkerProfile) async throws {
    guard let farmId = currentFarmId else {
        throw FarmDataError.noFarmSelected
    }

    let db = Firestore.firestore()
    try db.collection("farms").document(farmId)
        .collection("workerProfiles")
        .document(profile.id)
        .setData(from: profile)
}

func loadWorkerProfile(userId: String) async throws -> WorkerProfile? {
    guard let farmId = currentFarmId else {
        throw FarmDataError.noFarmSelected
    }

    let db = Firestore.firestore()
    let doc = try await db.collection("farms").document(farmId)
        .collection("workerProfiles")
        .document(userId)
        .getDocument()

    return try doc.data(as: WorkerProfile.self)
}

func loadAllWorkerProfiles() async throws -> [WorkerProfile] {
    guard let farmId = currentFarmId else {
        throw FarmDataError.noFarmSelected
    }

    let db = Firestore.firestore()
    let snapshot = try await db.collection("farms").document(farmId)
        .collection("workerProfiles")
        .getDocuments()

    return snapshot.documents.compactMap { try? $0.data(as: WorkerProfile.self) }
}
```

#### 2.2: Add CropStats Methods

```swift
// MARK: - Crop Statistics

func saveCropStats(_ stats: CropStats) async throws {
    guard let farmId = currentFarmId else {
        throw FarmDataError.noFarmSelected
    }

    let db = Firestore.firestore()
    try db.collection("farms").document(farmId)
        .collection("cropStats")
        .document(stats.id)
        .setData(from: stats)
}

func loadCropStats(cropName: String) async throws -> CropStats? {
    guard let farmId = currentFarmId else {
        throw FarmDataError.noFarmSelected
    }

    let cropId = cropName.lowercased().replacingOccurrences(of: " ", with: "-")

    let db = Firestore.firestore()
    let doc = try await db.collection("farms").document(farmId)
        .collection("cropStats")
        .document(cropId)
        .getDocument()

    return try doc.data(as: CropStats.self)
}

func loadAllCropStats() async throws -> [CropStats] {
    guard let farmId = currentFarmId else {
        throw FarmDataError.noFarmSelected
    }

    let db = Firestore.firestore()
    let snapshot = try await db.collection("farms").document(farmId)
        .collection("cropStats")
        .getDocuments()

    return snapshot.documents.compactMap { try? $0.data(as: CropStats.self) }
}
```

#### 2.3: Add HarvestForecast Methods

```swift
// MARK: - Harvest Forecasts

func saveHarvestForecast(_ forecast: HarvestForecast) async throws {
    guard let farmId = currentFarmId else {
        throw FarmDataError.noFarmSelected
    }

    let db = Firestore.firestore()
    try db.collection("farms").document(farmId)
        .collection("harvestForecasts")
        .document(forecast.id)
        .setData(from: forecast)
}

func loadHarvestForecasts(isCurrent: Bool = true) async throws -> [HarvestForecast] {
    guard let farmId = currentFarmId else {
        throw FarmDataError.noFarmSelected
    }

    let db = Firestore.firestore()
    let snapshot = try await db.collection("farms").document(farmId)
        .collection("harvestForecasts")
        .whereField("isCurrent", isEqualTo: isCurrent)
        .order(by: "expectedHarvestStart")
        .getDocuments()

    return snapshot.documents.compactMap { try? $0.data(as: HarvestForecast.self) }
}

func loadHarvestForecastsForDateRange(start: Date, end: Date) async throws -> [HarvestForecast] {
    guard let farmId = currentFarmId else {
        throw FarmDataError.noFarmSelected
    }

    let db = Firestore.firestore()
    let snapshot = try await db.collection("farms").document(farmId)
        .collection("harvestForecasts")
        .whereField("isCurrent", isEqualTo: true)
        .whereField("expectedHarvestStart", isGreaterThanOrEqualTo: start)
        .whereField("expectedHarvestStart", isLessThanOrEqualTo: end)
        .getDocuments()

    return snapshot.documents.compactMap { try? $0.data(as: HarvestForecast.self) }
}
```

#### 2.4: Add ProductionPlan Methods

```swift
// MARK: - Production Plans

func saveProductionPlan(_ plan: ProductionPlan) async throws {
    guard let farmId = currentFarmId else {
        throw FarmDataError.noFarmSelected
    }

    let db = Firestore.firestore()
    try db.collection("farms").document(farmId)
        .collection("productionPlans")
        .document(plan.id)
        .setData(from: plan)
}

func loadProductionPlans(status: PlanningStatus? = nil) async throws -> [ProductionPlan] {
    guard let farmId = currentFarmId else {
        throw FarmDataError.noFarmSelected
    }

    let db = Firestore.firestore()
    var query: Query = db.collection("farms").document(farmId)
        .collection("productionPlans")

    if let status = status {
        query = query.whereField("planningStatus", isEqualTo: status.rawValue)
    }

    let snapshot = try await query.getDocuments()

    return snapshot.documents.compactMap { try? $0.data(as: ProductionPlan.self) }
}

func updateProductionPlan(_ plan: ProductionPlan) async throws {
    try await saveProductionPlan(plan)
}
```

---

## 🔄 Phase 3: Create Data Migration Script

### Goal:
Migrate existing beds to have availability status and create initial analytics

### Steps:

#### 3.1: Create Migration View

Create a new file: `FarmiculturAPP/MigrationView.swift`

```swift
import SwiftUI

struct MigrationView: View {
    @EnvironmentObject var dataService: FarmDataService
    @State private var migrationStatus = "Not started"
    @State private var isMigrating = false
    @State private var progress: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Data Migration for MCP")
                .font(.title)

            Text(migrationStatus)
                .multilineTextAlignment(.center)
                .padding()

            if isMigrating {
                ProgressView(value: progress, total: 1.0)
                    .padding()
            }

            Button("Start Migration") {
                Task {
                    await runMigration()
                }
            }
            .disabled(isMigrating)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    func runMigration() async {
        isMigrating = true
        migrationStatus = "Starting migration..."
        progress = 0

        do {
            // Step 1: Migrate bed availability
            migrationStatus = "Migrating bed availability..."
            try await migrateBedAvailability()
            progress = 0.33

            // Step 2: Generate crop stats
            migrationStatus = "Generating crop statistics..."
            try await generateCropStats()
            progress = 0.66

            // Step 3: Create harvest forecasts
            migrationStatus = "Creating harvest forecasts..."
            try await generateHarvestForecasts()
            progress = 1.0

            migrationStatus = "Migration completed successfully!"
        } catch {
            migrationStatus = "Migration failed: \\(error.localizedDescription)"
        }

        isMigrating = false
    }

    func migrateBedAvailability() async throws {
        let beds = try await dataService.loadAllBeds()

        for bed in beds {
            var updatedBed = bed

            // Set availability based on current status
            switch bed.status {
            case .dirty, .clean, .prepared:
                updatedBed.availabilityStatus = .available
                updatedBed.availableFrom = Date()
            case .planted, .growing, .harvesting:
                updatedBed.availabilityStatus = .occupied
            case .completed:
                updatedBed.availabilityStatus = .available
                updatedBed.availableFrom = Date()
            }

            // Set last crop name
            if let currentCrop = bed.currentCropName {
                updatedBed.lastCropName = currentCrop
            }

            try await dataService.updateBed(updatedBed)
        }
    }

    func generateCropStats() async throws {
        let completedBeds = try await dataService.loadCompletedBeds()
        var cropAggregates: [String: [CompletedBed]] = [:]

        // Group by crop name
        for bed in completedBeds {
            let cropName = bed.bedSnapshot.currentCropName ?? "Unknown"
            cropAggregates[cropName, default: []].append(bed)
        }

        // Create CropStats for each crop
        for (cropName, beds) in cropAggregates {
            guard beds.count > 0 else { continue }

            let totalYield = beds.reduce(0) { $0 + $1.totalHarvested }
            let avgYield = totalYield / Double(beds.count)

            let totalDays = beds.reduce(0) { $0 + $1.durationDays }
            let avgDays = totalDays / beds.count

            // Quality: excellent=4, good=3, fair=2, poor=1
            let totalQuality = beds.flatMap { $0.bedSnapshot.harvestReports }
                .compactMap { $0.quality }
                .reduce(0.0) { sum, quality in
                    sum + (quality == .excellent ? 4 : quality == .good ? 3 : quality == .fair ? 2 : 1)
                }
            let reportCount = beds.flatMap { $0.bedSnapshot.harvestReports }.count
            let avgQuality = reportCount > 0 ? totalQuality / Double(reportCount) : 0

            var stats = CropStats(
                id: cropName.lowercased().replacingOccurrences(of: " ", with: "-"),
                cropName: cropName,
                farmId: dataService.currentFarmId ?? ""
            )

            stats.totalBedsGrown = beds.count
            stats.totalBedsCompleted = beds.count
            stats.avgYieldPerBed = avgYield
            stats.avgYieldUnit = beds.first?.harvestUnit ?? .kilograms
            stats.avgDaysToMaturity = avgDays
            stats.avgQualityRating = avgQuality
            stats.successRate = Double(beds.filter { $0.totalHarvested > 0 }.count) / Double(beds.count)
            stats.dataSourceBeds = beds.map { $0.id }

            try await dataService.saveCropStats(stats)
        }
    }

    func generateHarvestForecasts() async throws {
        let beds = try await dataService.loadAllBeds()

        for bed in beds {
            // Only create forecasts for growing beds
            guard bed.status == .growing || bed.status == .planted,
                  let harvestStart = bed.expectedHarvestStart,
                  let datePlanted = bed.datePlanted,
                  let cropName = bed.currentCropName else {
                continue
            }

            let firstVariety = bed.varieties.first
            let maturityDays = firstVariety?.daysToMaturity ?? 60

            // Try to get historical average
            let cropStats = try? await dataService.loadCropStats(cropName: cropName)

            var forecast = HarvestForecast(
                id: "forecast-\\(bed.id)",
                bedId: bed.id,
                cropName: cropName,
                varieties: bed.varieties.map { $0.name },
                expectedHarvestStart: harvestStart,
                expectedHarvestEnd: bed.expectedHarvestEnd,
                estimatedQuantity: cropStats?.avgYieldPerBed ?? 0,
                estimatedUnit: cropStats?.avgYieldUnit ?? .kilograms,
                confidenceLevel: cropStats != nil ? 75 : 50,
                basedOnMaturityDays: maturityDays,
                datePlanted: datePlanted,
                plantCount: bed.totalPlantCount,
                historicalAvgYield: cropStats?.avgYieldPerBed
            )

            try await dataService.saveHarvestForecast(forecast)
        }
    }
}
```

#### 3.2: Add Migration Button to Settings or Admin Panel

Add this to your main settings/admin view:

```swift
NavigationLink("Run MCP Migration") {
    MigrationView()
        .environmentObject(dataService)
}
```

---

## 🔄 Phase 4: Build Node.js MCP Server

### Goal:
Create a standalone MCP server that exposes farm data through standardized tools

### Steps:

#### 4.1: Create MCP Server Project

```bash
# Create project directory
mkdir farmiculture-mcp-server
cd farmiculture-mcp-server

# Initialize Node.js project
npm init -y

# Install dependencies
npm install @modelcontextprotocol/sdk firebase-admin dotenv
npm install -D typescript @types/node tsx

# Initialize TypeScript
npx tsc --init
```

#### 4.2: Update `tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```

#### 4.3: Update `package.json`

Add these scripts:

```json
{
  "type": "module",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "tsx src/index.ts"
  }
}
```

#### 4.4: Create Firebase Config

Create `src/firebase/config.ts`:

```typescript
import admin from 'firebase-admin';
import * as dotenv from 'dotenv';

dotenv.config();

// Initialize Firebase Admin
const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
if (!serviceAccountKey) {
  throw new Error('FIREBASE_SERVICE_ACCOUNT_KEY environment variable not set');
}

const serviceAccount = JSON.parse(serviceAccountKey);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: process.env.FIREBASE_PROJECT_ID
});

export const db = admin.firestore();
export const auth = admin.auth();
```

#### 4.5: Create Query Functions

Create `src/firebase/queries.ts`:

```typescript
import { db } from './config.js';

export interface AvailableBedsQuery {
  farmId: string;
  cropAreaId?: string;
  sectionId?: string;
  availabilityStatus?: 'available' | 'reserved';
}

export async function queryAvailableBeds(params: AvailableBedsQuery) {
  const { farmId, cropAreaId, sectionId, availabilityStatus = 'available' } = params;

  // Get all crop areas
  let areasQuery = db.collection(`farms/${farmId}/cropAreas`);
  if (cropAreaId) {
    areasQuery = areasQuery.where('id', '==', cropAreaId) as any;
  }

  const areasSnapshot = await areasQuery.get();
  const allBeds: any[] = [];

  // Traverse hierarchy: Areas → Sections → Beds
  for (const areaDoc of areasSnapshot.docs) {
    const areaData = areaDoc.data();

    // Get sections in this area
    let sectionsQuery = db.collection(`farms/${farmId}/cropAreas/${areaDoc.id}/sections`);
    if (sectionId) {
      sectionsQuery = sectionsQuery.where('id', '==', sectionId) as any;
    }

    const sectionsSnapshot = await sectionsQuery.get();

    for (const sectionDoc of sectionsSnapshot.docs) {
      const sectionData = sectionDoc.data();

      // Get beds in this section with availability filter
      const bedsSnapshot = await db
        .collection(`farms/${farmId}/cropAreas/${areaDoc.id}/sections/${sectionDoc.id}/beds`)
        .where('availabilityStatus', '==', availabilityStatus)
        .get();

      for (const bedDoc of bedsSnapshot.docs) {
        allBeds.push({
          id: bedDoc.id,
          ...bedDoc.data(),
          areaId: areaDoc.id,
          areaName: areaData.name,
          areaType: areaData.type,
          sectionId: sectionDoc.id,
          sectionName: sectionData.name
        });
      }
    }
  }

  return {
    count: allBeds.length,
    beds: allBeds
  };
}

export async function queryUpcomingHarvests(
  farmId: string,
  startDate: Date,
  endDate: Date,
  cropName?: string
) {
  let query: any = db.collection(`farms/${farmId}/harvestForecasts`)
    .where('isCurrent', '==', true)
    .where('expectedHarvestStart', '>=', startDate)
    .where('expectedHarvestStart', '<=', endDate);

  if (cropName) {
    query = query.where('cropName', '==', cropName);
  }

  const snapshot = await query.get();

  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
}

export async function queryWorkerPerformance(
  farmId: string,
  workerId: string,
  startDate: Date,
  endDate: Date
) {
  // Get harvest reports
  const harvestSnapshot = await db
    .collection(`farms/${farmId}/harvestReports`)
    .where('reportedBy', '==', workerId)
    .where('date', '>=', startDate)
    .where('date', '<=', endDate)
    .get();

  // Get completed tasks
  const tasksSnapshot = await db
    .collection(`farms/${farmId}/tasks`)
    .where('assignedTo', '==', workerId)
    .where('isCompleted', '==', true)
    .where('completedDate', '>=', startDate)
    .where('completedDate', '<=', endDate)
    .get();

  const harvestReports = harvestSnapshot.docs.map(d => d.data());
  const totalQuantity = harvestReports.reduce((sum, r) => sum + (r.quantity || 0), 0);

  const qualityMap = { excellent: 4, good: 3, fair: 2, poor: 1 };
  const avgQuality = harvestReports.length > 0
    ? harvestReports.reduce((sum, r) => sum + (qualityMap[r.quality as keyof typeof qualityMap] || 0), 0) / harvestReports.length
    : 0;

  return {
    workerId,
    period: {
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString()
    },
    harvests: {
      count: harvestReports.length,
      totalQuantity,
      averageQuality: avgQuality
    },
    tasks: {
      completed: tasksSnapshot.size
    }
  };
}

export async function queryCropPerformance(farmId: string, cropName: string) {
  const cropId = cropName.toLowerCase().replace(/\\s+/g, '-');

  const doc = await db
    .collection(`farms/${farmId}/cropStats`)
    .doc(cropId)
    .get();

  if (!doc.exists) {
    return null;
  }

  return {
    id: doc.id,
    ...doc.data()
  };
}

export async function suggestNextPlanting(
  farmId: string,
  targetHarvestDate?: Date,
  cropPreferences?: string[],
  numberOfBeds?: number
) {
  // Get available beds
  const availableBeds = await queryAvailableBeds({
    farmId,
    availabilityStatus: 'available'
  });

  // Get all crop stats
  const statsSnapshot = await db
    .collection(`farms/${farmId}/cropStats`)
    .get();

  const cropStats = statsSnapshot.docs.map(d => ({
    id: d.id,
    ...d.data()
  }));

  // Filter by preferences if provided
  let suggestedCrops = cropStats;
  if (cropPreferences && cropPreferences.length > 0) {
    suggestedCrops = cropStats.filter(c =>
      cropPreferences.some(pref =>
        c.cropName.toLowerCase().includes(pref.toLowerCase())
      )
    );
  }

  // Sort by success rate and yield
  suggestedCrops.sort((a: any, b: any) => {
    const scoreA = (a.successRate || 0) * (a.avgYieldPerBed || 0);
    const scoreB = (b.successRate || 0) * (b.avgYieldPerBed || 0);
    return scoreB - scoreA;
  });

  // Calculate planting dates based on target harvest
  const suggestions = suggestedCrops.slice(0, numberOfBeds || 5).map((crop: any) => {
    let plantingDate = new Date();
    if (targetHarvestDate) {
      const daysToMaturity = crop.avgDaysToMaturity || 60;
      plantingDate = new Date(targetHarvestDate);
      plantingDate.setDate(plantingDate.getDate() - daysToMaturity);
    }

    return {
      cropName: crop.cropName,
      expectedYield: crop.avgYieldPerBed,
      yieldUnit: crop.avgYieldUnit,
      successRate: crop.successRate,
      avgDaysToMaturity: crop.avgDaysToMaturity,
      recommendedPlantingDate: plantingDate.toISOString(),
      availableBeds: Math.min(availableBeds.count, numberOfBeds || 3)
    };
  });

  return {
    totalAvailableBeds: availableBeds.count,
    suggestions
  };
}

export async function createTask(farmId: string, task: any) {
  const taskRef = db.collection(`farms/${farmId}/tasks`).doc();

  const newTask = {
    id: taskRef.id,
    ...task,
    createdDate: new Date(),
    isCompleted: false
  };

  await taskRef.set(newTask);

  return newTask;
}

export async function updateBedStatus(
  farmId: string,
  bedId: string,
  newStatus: string,
  changedBy: string,
  notes?: string
) {
  // First, need to find the bed (it's nested in area/section)
  // This is a simplified version - you'd need to query to find the right path

  return {
    success: true,
    message: 'Bed status update not fully implemented - requires path lookup',
    bedId,
    newStatus
  };
}
```

#### 4.6: Create MCP Server

Create `src/index.ts`:

```typescript
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import {
  queryAvailableBeds,
  queryUpcomingHarvests,
  queryWorkerPerformance,
  queryCropPerformance,
  suggestNextPlanting,
  createTask
} from './firebase/queries.js';

const server = new Server(
  {
    name: 'farmiculture-mcp-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Define tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'query_available_beds',
        description: 'Find beds that are ready for planting. Returns count and list of available beds with their location.',
        inputSchema: {
          type: 'object',
          properties: {
            farmId: {
              type: 'string',
              description: 'Farm ID'
            },
            cropAreaId: {
              type: 'string',
              description: 'Optional: Filter by crop area ID'
            },
            sectionId: {
              type: 'string',
              description: 'Optional: Filter by section ID'
            },
            availabilityStatus: {
              type: 'string',
              enum: ['available', 'reserved'],
              description: 'Availability status to filter by (default: available)'
            }
          },
          required: ['farmId']
        }
      },
      {
        name: 'query_upcoming_harvests',
        description: 'Get beds that will be ready to harvest within a date range. Returns forecast data including expected dates and quantities.',
        inputSchema: {
          type: 'object',
          properties: {
            farmId: { type: 'string', description: 'Farm ID' },
            startDate: { type: 'string', description: 'Start date in ISO 8601 format' },
            endDate: { type: 'string', description: 'End date in ISO 8601 format' },
            cropName: { type: 'string', description: 'Optional: Filter by crop name' }
          },
          required: ['farmId', 'startDate', 'endDate']
        }
      },
      {
        name: 'query_worker_performance',
        description: 'Get worker productivity metrics including harvests and tasks completed within a date range.',
        inputSchema: {
          type: 'object',
          properties: {
            farmId: { type: 'string', description: 'Farm ID' },
            workerId: { type: 'string', description: 'Worker user ID' },
            startDate: { type: 'string', description: 'Start date in ISO 8601 format' },
            endDate: { type: 'string', description: 'End date in ISO 8601 format' }
          },
          required: ['farmId', 'workerId', 'startDate', 'endDate']
        }
      },
      {
        name: 'query_crop_performance',
        description: 'Get historical yield and performance data for a specific crop.',
        inputSchema: {
          type: 'object',
          properties: {
            farmId: { type: 'string', description: 'Farm ID' },
            cropName: { type: 'string', description: 'Name of the crop to analyze' }
          },
          required: ['farmId', 'cropName']
        }
      },
      {
        name: 'suggest_next_planting',
        description: 'Recommend what to plant based on available beds, crop performance, and optional target harvest date.',
        inputSchema: {
          type: 'object',
          properties: {
            farmId: { type: 'string', description: 'Farm ID' },
            targetHarvestDate: { type: 'string', description: 'Optional: Target harvest date in ISO 8601' },
            cropPreferences: {
              type: 'array',
              items: { type: 'string' },
              description: 'Optional: Preferred crop names'
            },
            numberOfBeds: { type: 'number', description: 'Optional: Number of beds to plant' }
          },
          required: ['farmId']
        }
      },
      {
        name: 'create_task',
        description: 'Create a new task in the farm management system.',
        inputSchema: {
          type: 'object',
          properties: {
            farmId: { type: 'string', description: 'Farm ID' },
            title: { type: 'string', description: 'Task title' },
            taskDescription: { type: 'string', description: 'Task description' },
            assignedTo: { type: 'string', description: 'Optional: Worker user ID to assign' },
            dueDate: { type: 'string', description: 'Optional: Due date in ISO 8601' },
            priority: {
              type: 'string',
              enum: ['low', 'medium', 'high', 'urgent'],
              description: 'Task priority level'
            },
            bedId: { type: 'string', description: 'Optional: Bed ID if task is bed-specific' },
            sectionId: { type: 'string', description: 'Optional: Section ID if task is section-specific' },
            cropAreaId: { type: 'string', description: 'Optional: Crop area ID if task is area-specific' }
          },
          required: ['farmId', 'title', 'priority']
        }
      }
    ]
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'query_available_beds': {
        const result = await queryAvailableBeds(args as any);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2)
            }
          ]
        };
      }

      case 'query_upcoming_harvests': {
        const result = await queryUpcomingHarvests(
          args.farmId,
          new Date(args.startDate),
          new Date(args.endDate),
          args.cropName
        );
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2)
            }
          ]
        };
      }

      case 'query_worker_performance': {
        const result = await queryWorkerPerformance(
          args.farmId,
          args.workerId,
          new Date(args.startDate),
          new Date(args.endDate)
        );
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2)
            }
          ]
        };
      }

      case 'query_crop_performance': {
        const result = await queryCropPerformance(args.farmId, args.cropName);
        return {
          content: [
            {
              type: 'text',
              text: result ? JSON.stringify(result, null, 2) : 'No data found for this crop'
            }
          ]
        };
      }

      case 'suggest_next_planting': {
        const result = await suggestNextPlanting(
          args.farmId,
          args.targetHarvestDate ? new Date(args.targetHarvestDate) : undefined,
          args.cropPreferences,
          args.numberOfBeds
        );
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2)
            }
          ]
        };
      }

      case 'create_task': {
        const result = await createTask(args.farmId, args);
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(result, null, 2)
            }
          ]
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error: any) {
    return {
      content: [
        {
          type: 'text',
          text: `Error: ${error.message}`
        }
      ],
      isError: true
    };
  }
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('Farmiculture MCP Server running on stdio');
}

main().catch(console.error);
```

#### 4.7: Create `.env` File

Create `.env` in the root:

```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account","project_id":"..."}
```

To get your service account key:
1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Copy the entire JSON and paste as one line in `.env`

---

## 🔄 Phase 5: Test MCP Server with Inspector

### Steps:

#### 5.1: Install MCP Inspector

```bash
npm install -g @modelcontextprotocol/inspector
```

#### 5.2: Run Inspector

```bash
cd farmiculture-mcp-server
npx @modelcontextprotocol/inspector tsx src/index.ts
```

#### 5.3: Test Each Tool

In the Inspector UI:
1. Test `query_available_beds` with your farmId
2. Test `suggest_next_planting`
3. Test `create_task`

Verify all tools return correct data.

---

## 🔄 Phase 6: Build Swift MCP Client

### Goal:
Create a Swift package that implements the MCP client protocol

### Steps:

#### 6.1: Create Swift Package

Create `FarmiculturAPP/MCPClient/` directory with `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MCPClient",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "MCPClient",
            targets: ["MCPClient"]),
    ],
    targets: [
        .target(
            name: "MCPClient",
            dependencies: []),
    ]
)
```

#### 6.2: Create MCP Protocol Types

Create `MCPClient/Sources/MCPClient/MCPTypes.swift`:

```swift
import Foundation

// MCP Protocol Types
public struct MCPRequest: Codable {
    public let jsonrpc: String = "2.0"
    public let id: Int
    public let method: String
    public let params: [String: AnyCodable]?

    public init(id: Int, method: String, params: [String: AnyCodable]? = nil) {
        self.id = id
        self.method = method
        self.params = params
    }
}

public struct MCPResponse: Codable {
    public let jsonrpc: String
    public let id: Int
    public let result: AnyCodable?
    public let error: MCPError?
}

public struct MCPError: Codable {
    public let code: Int
    public let message: String
    public let data: AnyCodable?
}

// Helper for dynamic JSON
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
```

This guide continues with Phase 6-8 in a separate document...

---

## Next Steps

1. Complete Phase 2 (FarmDataService updates) - I can help you add all the methods
2. Test the migration script
3. Build and test the MCP server
4. Create the Swift MCP client
5. Add UI for natural language queries

Would you like me to continue with the remaining phases, or would you prefer to implement Phase 2 first and test it?
