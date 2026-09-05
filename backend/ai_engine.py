import math
import re
import random

def calculate_distance(lat1, lon1, lat2, lon2):
    """
    Calculate Haversine distance in km between two points.
    """
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) * math.sin(dlat / 2) +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon / 2) * math.sin(dlon / 2))
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def calculate_text_similarity(text1, text2):
    """
    Use pure Python Jaccard similarity to avoid heavy C++ dependencies.
    (Simulates the NLTK / spaCy / DistilBERT pipeline for the hackathon MVP)
    """
    if not text1 or not text2:
        return 0.0
    
    words1 = set(re.findall(r'\w+', text1.lower()))
    words2 = set(re.findall(r'\w+', text2.lower()))
    
    intersection = len(words1.intersection(words2))
    union = len(words1.union(words2))
    
    if union == 0:
        return 0.0
    return float(intersection) / union

def detect_duplicates(new_complaint, existing_complaints):
    """
    Rule: Distance <= 0.005 km (5m) AND text similarity >= 0.75
    """
    is_duplicate = False
    duplicate_of = None
    highest_sim = 0.0

    new_lat = new_complaint.get('lat')
    new_lng = new_complaint.get('lng')
    new_desc = new_complaint.get('description', '')

    for comp in existing_complaints:
        comp_lat = comp.get('lat')
        comp_lng = comp.get('lng')
        comp_desc = comp.get('description', '')

        if not comp_lat or not comp_lng:
            continue

        dist = calculate_distance(new_lat, new_lng, comp_lat, comp_lng)
        if dist <= 0.005:
            sim = calculate_text_similarity(new_desc, comp_desc)
            if sim >= 0.75 and sim > highest_sim:
                highest_sim = sim
                is_duplicate = True
                duplicate_of = comp.get('id')

    return is_duplicate, duplicate_of, highest_sim

def predict_urgency(text):
    """
    Mock NLP function to detect urgency words. 
    Simulates a BERT/DistilBERT urgency classifier.
    """
    urgent_words = ['urgent', 'hazard', 'bleeding', 'accident', 'huge', 'broken', 'danger']
    text_lower = text.lower()
    score = 40 # Base score
    
    for word in urgent_words:
        if re.search(r'\b' + word + r'\b', text_lower):
            score += 20
            
    return min(score, 100)

def simulate_yolo_vision(image_path):
    """
    Simulates a PyTorch YOLOv8 inference step.
    Returns a mock confidence score.
    """
    return random.randint(70, 98)

def calculate_severity_score(image_conf, text_urgency, location_importance, duplicate_score):
    """
    Applies the mathematical PRD formula for Severity.
    severity = (0.20 * image) + (0.40 * text) + (0.30 * loc) + (0.10 * dup)
    """
    score = (0.20 * image_conf) + (0.40 * text_urgency) + (0.30 * location_importance) + (0.10 * duplicate_score)
    return round(score)

def get_priority_level(score):
    if score >= 80: return 'Critical'
    if score >= 60: return 'High'
    if score >= 40: return 'Medium'
    return 'Low'

def process_complaint_ai(complaint_data, existing_complaints):
    """
    Full AI pipeline entry point.
    """
    # 1. Image analysis (YOLOv8 simulation)
    image_conf = simulate_yolo_vision(complaint_data.get('image_url'))
    
    # 2. Text analysis (NLP simulation)
    text_urgency = predict_urgency(complaint_data.get('description', ''))
    
    # 3. Duplicate detection
    is_dup, dup_id, sim_score = detect_duplicates(complaint_data, existing_complaints)
    dup_score = 10 if is_dup else 0  
    
    # 4. Location importance (Simulated static for now)
    loc_importance = 70
    
    # Calculate final severity
    severity_score = calculate_severity_score(image_conf, text_urgency, loc_importance, dup_score)
    priority = get_priority_level(severity_score)
    
    return {
        'image_confidence': image_conf,
        'text_urgency': text_urgency,
        'location_importance': loc_importance,
        'duplicate_score': dup_score,
        'is_duplicate': is_dup,
        'duplicate_of': dup_id,
        'severity_score': severity_score,
        'priority': priority,
        'ai_verified': True
    }
