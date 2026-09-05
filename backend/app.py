from flask import Flask, request, jsonify
from flask_cors import CORS
from supabase import create_client, Client
import os
from dotenv import load_dotenv
from ai_engine import process_complaint_ai
from datetime import datetime
from functools import wraps

# Load environment variables (Supabase credentials)
load_dotenv()

app = Flask(__name__)
CORS(app) # Allow frontend to call backend

# Initialize Supabase client
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")

if SUPABASE_URL and SUPABASE_KEY:
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    supabase_admin: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
else:
    print("WARNING: Supabase credentials not found. Make sure to set SUPABASE_URL and SUPABASE_KEY in .env")
    supabase = None
    supabase_admin = None

def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if not supabase:
            return jsonify({"error": "Supabase not configured"}), 500
            
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({"error": "Missing or invalid Authorization header"}), 401
        
        token = auth_header.split(' ')[1]
        try:
            # Verify token with Supabase
            user_response = supabase.auth.get_user(token)
            if not user_response or not user_response.user:
                return jsonify({"error": "Invalid token"}), 401
            # Inject user into request context
            request.user = user_response.user
        except Exception as e:
            return jsonify({"error": f"Authentication failed: {str(e)}"}), 401
            
        return f(*args, **kwargs)
    return decorated

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "Online", "service": "Flask API"})

@app.route('/api/auth/register', methods=['POST'])
def register():
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500
    
    data = request.json
    email = data.get('email')
    password = data.get('password')
    full_name = data.get('full_name')
    role = data.get('role', 'citizen')
    
    if not email or not password:
        return jsonify({"error": "Email and password required"}), 400
        
    try:
        res = supabase.auth.sign_up({
            "email": email,
            "password": password,
            "options": {
                "data": {
                    "full_name": full_name,
                    "role": role
                }
            }
        })
        return jsonify({
            "message": "Registration successful", 
            "user": {"id": res.user.id, "email": res.user.email}
        }), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/api/auth/login', methods=['POST'])
def login():
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500
    
    data = request.json
    email = data.get('email')
    password = data.get('password')
    
    if not email or not password:
        return jsonify({"error": "Email and password required"}), 400
        
    try:
        res = supabase.auth.sign_in_with_password({
            "email": email,
            "password": password
        })
        
        return jsonify({
            "token": res.session.access_token,
            "user": {
                "id": res.user.id,
                "email": res.user.email,
                "role": res.user.user_metadata.get('role', 'citizen')
            }
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 401

@app.route('/api/complaints', methods=['GET'])
def get_complaints():
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500
        
    try:
        response = supabase_admin.table('complaints').select("*").execute()
        return jsonify(response.data), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/complaints', methods=['POST'])
@require_auth
def create_complaint():
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500
        
    data = request.json
    if not data:
        return jsonify({"error": "No data provided"}), 400
        
    # Fetch existing complaints for duplicate detection
    existing_response = supabase_admin.table('complaints').select("id, lat, lng, description").execute()
    existing_complaints = existing_response.data
    
    # Process through AI Pipeline
    ai_results = process_complaint_ai(data, existing_complaints)
    
    # Construct final database record
    record = {
        "category_id": data.get("category_id"),
        "description": data.get("description"),
        "lat": data.get("lat"),
        "lng": data.get("lng"),
        "reported_by": data.get("reported_by", "anonymous"),
        "status": "open",
        "date_reported": datetime.utcnow().isoformat(),
        # AI Fields
        "image_confidence": ai_results['image_confidence'],
        "text_urgency": ai_results['text_urgency'],
        "location_importance": ai_results['location_importance'],
        "duplicate_score": ai_results['duplicate_score'],
        "is_duplicate": ai_results['is_duplicate'],
        "duplicate_of": ai_results['duplicate_of'],
        "severity_score": ai_results['severity_score'],
        "priority": ai_results['priority'],
        "ai_verified": ai_results['ai_verified']
    }
    
    try:
        response = supabase_admin.table('complaints').insert(record).execute()
        return jsonify(response.data[0]), 201
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

@app.route('/api/complaints/<string:complaint_id>', methods=['PATCH'])
@require_auth
def update_complaint_status(complaint_id):
    if not supabase:
        return jsonify({"error": "Supabase not configured"}), 500
        
    data = request.json
    if not data or 'status' not in data:
        return jsonify({"error": "Status is required"}), 400
        
    try:
        response = supabase_admin.table('complaints').update({"status": data['status']}).eq('id', complaint_id).execute()
        if not response.data:
            return jsonify({"error": "Complaint not found"}), 404
        return jsonify(response.data[0]), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5005)
