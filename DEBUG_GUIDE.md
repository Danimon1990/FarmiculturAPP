# Debug Guide - Why Beds Aren't Showing

## ✅ Confirmed Working

1. **Firebase has the data** - Verified 48 beds across 4 greenhouses
2. **Data structure is correct** - Matches app expectations exactly
3. **Loading functions are correct** - Code paths are valid

## 🔍 Possible Issues

### Issue #1: App is Using Wrong Farm ID (Most Likely)

**Check This First:**

1. Run the app in Xcode
2. Look at the console/logs when you open Areas tab
3. You should see logs like: `🔄 Loading sections for area: Cedar`
4. **Check if you see**: `❌ No farm ID for loading sections`

If you see "No farm ID", the problem is the app doesn't have your farm ID stored.

**Solution:**
- Sign out of the app
- Sign back in
- The app should detect your existing farm

### Issue #2: Multiple Farms in Firebase

Check if you have multiple farm documents:

```bash
node check-firebase-data.js
```

If you see multiple farms, the app might be using a different one.

**Solution:**
- Note the farm IDs in Firebase
- In the app, sign out and sign back in
- Or delete extra farm documents in Firebase Console

### Issue #3: App Cache

The app might be caching old (empty) data.

**Solution:**
1. In Xcode: **Product → Clean Build Folder** (Cmd+Shift+K)
2. Delete the app from simulator/device
3. Rebuild and run

### Issue #4: Firebase Rules

Check if Firestore security rules are blocking reads.

**Solution:**
1. Go to Firebase Console → Firestore Database → Rules
2. For testing, temporarily set:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```
3. Click **Publish**

## 🛠️ Debug Steps

### Step 1: Check Console Logs

When you run the app and tap on "Cedar", look for these logs in Xcode console:

**Good Signs:**
```
🔄 Loading sections for area: Cedar
✅ Loaded 2 sections
```

**Bad Signs:**
```
❌ No farm ID for loading sections
```
or no logs at all

### Step 2: Check Current Farm ID

Add this temporary code to check:

In `EnhancedAreasView.swift`, in the `loadCropAreas()` function, add:
```swift
print("🆔 Current Farm ID: \(farmService.currentFarmId ?? "NONE")")
print("🆔 Expected Farm ID: 22F24F81-D799-4054-95A4-6EF4AAC790E7")
```

### Step 3: Force Farm ID (Temporary Fix)

If the farm ID is wrong, you can temporarily force it in `FarmDataService.swift`:

Find the `currentFarmId` property and set it:
```swift
@Published var currentFarmId: String? = "22F24F81-D799-4054-95A4-6EF4AAC790E7"
```

This will help identify if it's a farm ID issue.

### Step 4: Check Firebase Connection

In `EnhancedAreasView.swift`, modify `loadCropAreas()`:

```swift
func loadCropAreas() {
    guard let farmId = farmService.currentFarmId else {
        print("❌ NO FARM ID!")
        return
    }

    print("🔍 Loading areas for farm: \(farmId)")
    isLoading = true

    Task {
        do {
            cropAreas = try await farmService.loadCropAreas(farmId: farmId)
            print("✅ Loaded \(cropAreas.count) areas")

            // NEW: Try to load sections for first area
            if let firstArea = cropAreas.first {
                print("🔍 Testing sections load for: \(firstArea.name)")
                let sections = try await farmService.loadSections(farmId: farmId, areaId: firstArea.id)
                print("✅ Test: Found \(sections.count) sections")

                // NEW: Try to load beds
                if let firstSection = sections.first {
                    print("🔍 Testing beds load for: \(firstSection.name)")
                    let beds = try await farmService.loadBeds(farmId: farmId, areaId: firstArea.id, sectionId: firstSection.id)
                    print("✅ Test: Found \(beds.count) beds")
                }
            }
        } catch {
            print("❌ Failed to load areas: \(error)")
        }
        isLoading = false
    }
}
```

This will tell you exactly where the loading fails.

## 🎯 Quick Fix to Try First

### Option A: Clean Slate

1. **Delete the app** from simulator/device
2. **Clean build folder**: Product → Clean Build Folder
3. **Rebuild**: Product → Build (Cmd+B)
4. **Run** the app
5. **Sign in** again
6. Check if data appears

### Option B: Check Farm Association

1. Open Firebase Console
2. Go to Firestore Database
3. Navigate to: `users/{your-user-id}`
4. Check if there's a `farmId` field
5. Make sure it matches: `22F24F81-D799-4054-95A4-6EF4AAC790E7`

## 📱 What to Look For

When the app works correctly, you should see:

### Areas Tab:
- ✅ 4 crop areas listed
- ✅ Map section at top
- ✅ Tap "Cedar" → See 2 sections

### Section View:
- ✅ "Section 1" with 8 beds
- ✅ "Section 2" with 8 beds

### Bed View:
- ✅ Bed 1-1: Basil (30 plants)
- ✅ Bed 1-2: Peppers (30 plants)
- etc.

## 🚨 If Nothing Works

Run this command to double-check Firebase:

```bash
cd /Users/danimore/Documents/APPs/FarmiculturAPP
node check-firebase-data.js
```

You should see:
```
📍 Found 4 crop areas
  ✅ Cedar (ID: d59e691a-0584-4cea-8eed-fb143cbee071)
     └─ 2 sections
        ├─ Section 1 (ID: ...)
        │  └─ 8 beds
```

If you see this but the app still shows empty, the issue is definitely in the app's farm ID or authentication.

## 💡 Most Likely Solution

Based on typical issues, try this:

1. **Check Xcode console** for farm ID logs
2. **Sign out** from the app
3. **Sign back in**
4. **Pull down to refresh** in Areas tab

The app probably just needs to reload the farm association.

---

Let me know what you see in the Xcode console when you tap on a greenhouse, and I can pinpoint the exact issue!
