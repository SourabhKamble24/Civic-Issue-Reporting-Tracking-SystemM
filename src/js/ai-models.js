export const CATEGORIES = [
  { id: 'pothole', label: 'Pothole' },
  { id: 'streetlight', label: 'Streetlight Outage' },
  { id: 'water_leak', label: 'Water Leakage' },
  { id: 'garbage', label: 'Garbage Accumulation' },
  { id: 'sidewalk', label: 'Broken Sidewalk' }
];

// --- AI LOGIC (As per PRD) ---

/**
 * Calculate Haversine distance between two coordinates in km
 */
export function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of the earth in km
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) * 
    Math.sin(dLon / 2) * Math.sin(dLon / 2); 
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)); 
  return R * c; // Distance in km
}

/**
 * Mock Cosine Similarity for text (returns 0-1)
 */
export function calculateCosineSimilarity(text1, text2) {
  // Simple word overlap for mock purposes
  const words1 = text1.toLowerCase().split(/\W+/);
  const words2 = text2.toLowerCase().split(/\W+/);
  const intersection = words1.filter(word => words2.includes(word));
  const union = new Set([...words1, ...words2]);
  return intersection.length / union.size;
}

/**
 * Detect if a new issue is a duplicate of an existing one.
 * Condition 1: Distance <= 0.005 km (5 meters)
 * Condition 2: Text similarity >= 0.75
 */
export function checkDuplicate(newIssue, existingIssues) {
  let highestSimilarity = 0;
  let isDuplicate = false;
  let duplicateOf = null;

  for (const issue of existingIssues) {
    if (issue.id === newIssue.id) continue;
    
    const distance = calculateDistance(
      newIssue.location.lat, newIssue.location.lng,
      issue.location.lat, issue.location.lng
    );

    if (distance <= 0.005) {
      const similarity = calculateCosineSimilarity(newIssue.description, issue.description);
      if (similarity >= 0.75 && similarity > highestSimilarity) {
        highestSimilarity = similarity;
        isDuplicate = true;
        duplicateOf = issue.id;
      }
    }
  }

  return { isDuplicate, duplicateOf, similarity: highestSimilarity };
}

/**
 * Calculate final severity score (0-100)
 * severity_score = (0.20 * image_confidence) + (0.40 * text_urgency) + (0.30 * location_importance) + (0.10 * duplicate_score)
 */
export function calculateSeverity(imageConfidence, textUrgency, locationImportance, duplicateScore) {
  const score = (0.20 * imageConfidence) + (0.40 * textUrgency) + (0.30 * locationImportance) + (0.10 * duplicateScore);
  return Math.round(score);
}

/**
 * Map Score to Priority Level
 */
export function getPriorityLevel(score) {
  if (score >= 80) return 'Critical';
  if (score >= 60) return 'High';
  if (score >= 40) return 'Medium';
  return 'Low';
}

// Helper to construct a full issue object with AI analysis
export function createIssue(data) {
  const severityScore = calculateSeverity(data.imageConfidence, data.textUrgency, data.locationImportance, data.duplicateScore);
  const priority = getPriorityLevel(severityScore);
  
  return {
    ...data,
    severityScore,
    priority,
    aiVerified: true,
    estimatedResolutionTime: priority === 'Critical' ? '24 Hours' : priority === 'High' ? '48 Hours' : '3-5 Days'
  };
}

export const mockDataset = [
  createIssue({
    id: 'ISS-001',
    categoryId: 'pothole',
    status: 'open',
    description: 'Huge pothole on main highway causing traffic and vehicle damage. Urgent fix needed.',
    location: { lat: 28.6139, lng: 77.2090 },
    dateReported: '2026-08-15T10:00:00Z',
    reportedBy: 'user123',
    // AI Raw Inputs
    imageConfidence: 95,
    textUrgency: 90,
    locationImportance: 85,
    duplicateScore: 0 // Not a duplicate
  }),
  createIssue({
    id: 'ISS-002',
    categoryId: 'streetlight',
    status: 'in progress',
    description: 'Multiple streetlights out on 5th Avenue, making it unsafe at night.',
    location: { lat: 28.6200, lng: 77.2200 },
    dateReported: '2026-08-16T18:30:00Z',
    reportedBy: 'user456',
    imageConfidence: 88,
    textUrgency: 65,
    locationImportance: 70,
    duplicateScore: 10
  }),
  createIssue({
    id: 'ISS-003',
    categoryId: 'water_leak',
    status: 'open',
    description: 'Minor water pipe leak near the park entrance.',
    location: { lat: 28.6300, lng: 77.2100 },
    dateReported: '2026-08-17T08:15:00Z',
    reportedBy: 'user789',
    imageConfidence: 75,
    textUrgency: 40,
    locationImportance: 50,
    duplicateScore: 0
  }),
  createIssue({
    id: 'ISS-004',
    categoryId: 'garbage',
    status: 'resolved',
    description: 'Overflowing trash bins at the corner store.',
    location: { lat: 28.6000, lng: 77.1900 },
    dateReported: '2026-08-14T14:20:00Z',
    reportedBy: 'user101',
    imageConfidence: 90,
    textUrgency: 30,
    locationImportance: 40,
    duplicateScore: 0
  }),
  createIssue({
    id: 'ISS-005',
    categoryId: 'sidewalk',
    status: 'open',
    description: 'Sidewalk severely cracked, inaccessible for wheelchairs. Bleeding hazard.',
    location: { lat: 28.6150, lng: 77.2050 },
    dateReported: '2026-08-17T09:45:00Z',
    reportedBy: 'user123',
    imageConfidence: 92,
    textUrgency: 85, // High because of keywords like hazard, bleeding
    locationImportance: 60,
    duplicateScore: 5
  })
];
