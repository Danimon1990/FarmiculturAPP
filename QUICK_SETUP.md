# Quick Setup Guide - Populate Your Real Farm Data

## Your Farm Structure

The script will create this exact structure:

### 🏗️ **4 Greenhouses - 40 Total Beds**

1. **Cedar** (16 beds - 2 sections)
   - Section 1: Basil (1), Peppers (2-7), Rosemary (8)
   - Section 2: Celery (1), Peppers (2-7), Chives (8)

2. **Trees** (8 beds - 1 section)
   - Section 1: All Carrots (1-8)

3. **Big Cooler** (16 beds - 2 sections)
   - Section 1: Spinach, Lettuce, Radish, Kale, Pak Choi mix
   - Section 2: Spinach, Lettuce, Radish, Kale, Pak Choi mix

4. **Pond** (8 beds - 1 section)
   - Section 1: All Peppers (1-8)

**All beds**: 30 plants each, Status: Growing

---

## 3-Step Setup

### Step 1: Get Your Farm ID

Open your app, then check Firebase Console:
1. Go to https://console.firebase.google.com
2. Select your project
3. Click **Firestore Database**
4. Navigate to `farms` collection
5. **Copy the document ID** (looks like: `abc123-def456-ghi789`)

### Step 2: Download Service Account Key

1. In Firebase Console, click **⚙️ (Settings)** → **Project settings**
2. Go to **Service accounts** tab
3. Click **Generate new private key**
4. Save file as: `/Users/danimore/Documents/APPs/FarmiculturAPP/firebase-service-account.json`

### Step 3: Run the Script

```bash
cd /Users/danimore/Documents/APPs/FarmiculturAPP

# Install dependency
npm install firebase-admin

# Run with your Farm ID
FARM_ID="paste-your-farm-id-here" node populate-farm-data.js
```

---

## Expected Output

```
🌾 Populating data for farm: your-farm-id

📋 Creating crop areas, sections, and beds...

  ✅ Cedar (greenhouse)
    ↳ Section: Section 1
      → Bed 1-1: growing - Basil
      → Bed 1-2: growing - Peppers
      → Bed 1-3: growing - Peppers
      → Bed 1-4: growing - Peppers
      → Bed 1-5: growing - Peppers
      → Bed 1-6: growing - Peppers
      → Bed 1-7: growing - Peppers
      → Bed 1-8: growing - Rosemary
    ↳ Section: Section 2
      → Bed 2-1: growing - Celery
      → Bed 2-2: growing - Peppers
      ...

  ✅ Trees (greenhouse)
    ↳ Section: Section 1
      → Bed 1-1: growing - Carrots
      ...

  ✅ Big Cooler (greenhouse)
    ↳ Section: Section 1
      → Bed 1-1: growing - Spinach
      ...

  ✅ Pond (greenhouse)
    ↳ Section: Section 1
      → Bed 1-1: growing - Peppers
      ...

📝 Creating tasks...
  ✅ Clean the beds around the cedar house (high priority)
  ✅ Pick up the sand bags (medium priority)
  ✅ Start the basil seeds (high priority)
  ✅ Fertilize tomatoes (medium priority)
  ✅ Check irrigation system (high priority)

🔄 Committing to Firebase...
✨ Done! Your farm data has been populated.

📊 Summary:
  - 4 crop areas
  - 6 sections
  - 48 beds
  - 5 tasks

🌾 Your farm is ready to go!
✅ Script completed successfully
```

---

## Verify in App

1. **Open app** → Areas tab
2. **You should see**:
   - Cedar, Trees, Big Cooler, Pond in the list
   - Empty map (assign areas using Edit button)

3. **Tap "Cedar"** → You should see:
   - Section 1 with 8 beds
   - Section 2 with 8 beds

4. **Tap "View All Beds"** → Filter by status:
   - All 48 beds showing as "Growing"

5. **Chat tab** → Ask:
   - "How is the farm today?"
   - "What crops are we growing?"
   - "How many beds do we have?"

---

## Assign Areas to Map

After data is populated:

1. **Areas tab** → Tap **"Edit"** on map
2. **Tap a square** → Select a greenhouse
3. **Repeat** for other greenhouses
4. **Tap "Done"** to save

Example layout:
```
┌────┬────┬────┬────┐
│Cedar│Cedar│Trees│Pond│
├────┼────┼────┼────┤
│Cedar│Cedar│Trees│Pond│
├────┼────┼────┼────┤
│Big │Big │    │    │
│Cool│Cool│    │    │
└────┴────┴────┴────┘
```

---

## What You Get

✅ **4 greenhouses** with your exact crop layout
✅ **48 beds** with 30 plants each
✅ **6 sections** properly organized
✅ **All beds growing** with realistic planting dates
✅ **5 sample tasks** with priorities and due dates
✅ **Varieties included**: Genovese Basil, Bell Peppers, Nantes Carrots, etc.
✅ **Harvest dates calculated** based on crop maturity times

---

## Crops by Greenhouse

| Greenhouse | Crops |
|------------|-------|
| **Cedar** | Basil, Peppers, Rosemary, Celery, Chives |
| **Trees** | Carrots |
| **Big Cooler** | Spinach, Lettuce, Radish, Kale, Pak Choi |
| **Pond** | Peppers |

---

## Next Steps

After populating:

1. ✅ Test navigation by tapping areas
2. ✅ Assign areas to map squares
3. ✅ Try the Chat feature: "Give me a farm status"
4. ✅ Add harvest reports to some beds
5. ✅ Mark some tasks as complete

Your farm is now fully operational! 🌾
