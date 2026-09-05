--
-- PostgreSQL database dump
--

\restrict px8eLKLp5DzVMR8SjV0fSGQ5vx4Q0sRdwVxJZNMohcI7yfQ74MyzhB5fGduH61r

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: complaint_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.complaint_status AS ENUM (
    'submitted',
    'under_review',
    'ai_analyzed',
    'prioritized',
    'assigned',
    'accepted',
    'in_progress',
    'resolved',
    'verified',
    'rejected',
    'closed'
);


--
-- Name: evidence_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.evidence_type AS ENUM (
    'image',
    'video',
    'document'
);


--
-- Name: priority_level; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.priority_level AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'citizen',
    'municipal_officer',
    'department_officer',
    'field_worker',
    'government_admin',
    'system_admin'
);


--
-- Name: calculate_complaint_risk(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_complaint_risk(p_complaint_id bigint) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE

    v_ai_severity NUMERIC := 50;
    v_ai_confidence NUMERIC := 0.5;

    v_reported_severity NUMERIC := 50;
    v_reported_urgency NUMERIC := 50;

    v_location_score NUMERIC := 30;
    v_exposure_score NUMERIC := 30;
    v_infrastructure_score NUMERIC := 30;

    v_final_score NUMERIC;

    v_lat NUMERIC;
    v_lon NUMERIC;

    v_priority priority_level;

    v_sensitive_count INTEGER := 0;
    v_nearest_distance NUMERIC;

BEGIN

    -- --------------------------------------------------------
    -- 1. GET CITIZEN REPORT DATA
    -- --------------------------------------------------------

    SELECT
        COALESCE(c.reported_severity, 50),
        COALESCE(c.reported_urgency, 50),
        l.latitude,
        l.longitude
    INTO
        v_reported_severity,
        v_reported_urgency,
        v_lat,
        v_lon

    FROM complaints c
    JOIN locations l
        ON l.location_id = c.location_id

    WHERE c.complaint_id = p_complaint_id;


    -- --------------------------------------------------------
    -- 2. GET AI ANALYSIS
    -- --------------------------------------------------------

    SELECT
        COALESCE(estimated_severity, 50),
        COALESCE(confidence_score, 0.5)
    INTO
        v_ai_severity,
        v_ai_confidence

    FROM ai_analysis

    WHERE complaint_id = p_complaint_id

    ORDER BY analyzed_at DESC

    LIMIT 1;


    -- --------------------------------------------------------
    -- 3. LOCATION RISK
    -- Nearby sensitive locations increase risk
    -- --------------------------------------------------------

    SELECT
        COUNT(*),
        MIN(
            ST_Distance(
                ST_SetSRID(
                    ST_MakePoint(v_lon, v_lat),
                    4326
                )::geography,

                geom::geography
            )
        )

    INTO
        v_sensitive_count,
        v_nearest_distance

    FROM nearby_sensitive_locations

    WHERE ST_DWithin(
        ST_SetSRID(
            ST_MakePoint(v_lon, v_lat),
            4326
        )::geography,

        geom::geography,

        500
    );


    -- --------------------------------------------------------
    -- LOCATION SCORE
    -- --------------------------------------------------------

    IF v_nearest_distance IS NULL THEN

        v_location_score := 20;

    ELSIF v_nearest_distance <= 50 THEN

        v_location_score := 100;

    ELSIF v_nearest_distance <= 100 THEN

        v_location_score := 90;

    ELSIF v_nearest_distance <= 250 THEN

        v_location_score := 75;

    ELSIF v_nearest_distance <= 500 THEN

        v_location_score := 55;

    ELSE

        v_location_score := 30;

    END IF;


    -- --------------------------------------------------------
    -- 4. PUBLIC EXPOSURE
    -- --------------------------------------------------------

    -- Demo exposure model.
    -- Later this can use population / traffic / mobility data.

    v_exposure_score :=
        LEAST(
            100,
            30 +
            (v_sensitive_count * 20)
        );


    -- --------------------------------------------------------
    -- 5. INFRASTRUCTURE CRITICALITY
    -- --------------------------------------------------------

    SELECT
        COALESCE(
            MAX(
                GREATEST(
                    COALESCE(condition_score, 50),
                    COALESCE(criticality_score, 50)
                )
            ),
            50
        )

    INTO v_infrastructure_score

    FROM infrastructure_assets ia

    JOIN complaints c
        ON c.asset_id = ia.asset_id

    WHERE c.complaint_id = p_complaint_id;


    -- --------------------------------------------------------
    -- 6. FINAL RISK SCORE
    -- --------------------------------------------------------

    v_final_score :=
          (v_ai_severity * 0.30)
        + (v_location_score * 0.20)
        + (v_exposure_score * 0.15)
        + (v_infrastructure_score * 0.15)
        + (v_reported_urgency * 0.10)
        + ((v_ai_confidence * 100) * 0.10);


    -- --------------------------------------------------------
    -- LIMIT SCORE BETWEEN 0 AND 100
    -- --------------------------------------------------------

    v_final_score :=
        GREATEST(
            0,
            LEAST(
                100,
                ROUND(v_final_score, 2)
            )
        );


    -- --------------------------------------------------------
    -- 7. PRIORITY LEVEL
    -- --------------------------------------------------------

    IF v_final_score >= 80 THEN

        v_priority := 'critical';

    ELSIF v_final_score >= 60 THEN

        v_priority := 'high';

    ELSIF v_final_score >= 40 THEN

        v_priority := 'medium';

    ELSE

        v_priority := 'low';

    END IF;


    -- --------------------------------------------------------
    -- 8. STORE RESULT
    -- --------------------------------------------------------

    INSERT INTO risk_scores
    (
        complaint_id,
        severity_score,
        location_score,
        exposure_score,
        infrastructure_score,
        urgency_score,
        evidence_score,
        final_risk_score,
        priority
    )

    VALUES
    (
        p_complaint_id,
        v_ai_severity,
        v_location_score,
        v_exposure_score,
        v_infrastructure_score,
        v_reported_urgency,
        v_ai_confidence * 100,
        v_final_score,
        v_priority
    );


    -- --------------------------------------------------------
    -- 9. UPDATE COMPLAINT
    -- --------------------------------------------------------

    UPDATE complaints

    SET
        priority = v_priority,
        status = 'prioritized',
        updated_at = NOW()

    WHERE complaint_id = p_complaint_id;


    -- --------------------------------------------------------
    -- 10. ADD TO PRIORITY QUEUE
    -- --------------------------------------------------------

    INSERT INTO priority_queue
    (
        complaint_id,
        risk_score,
        priority
    )

    VALUES
    (
        p_complaint_id,
        v_final_score,
        v_priority
    )

    ON CONFLICT (complaint_id)

    DO UPDATE SET

        risk_score = EXCLUDED.risk_score,
        priority = EXCLUDED.priority,
        last_updated = NOW();


    RETURN v_final_score;

END;
$$;


--
-- Name: detect_duplicate_complaints(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.detect_duplicate_complaints(p_complaint_id bigint) RETURNS TABLE(possible_duplicate_id bigint, distance_meters numeric, similarity_score numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_location GEOMETRY;
    v_category BIGINT;
BEGIN

    -- Get complaint location and category
    SELECT
        l.geom,
        c.category_id
    INTO
        v_location,
        v_category
    FROM complaints c
    JOIN locations l
        ON l.location_id = c.location_id
    WHERE c.complaint_id = p_complaint_id;


    RETURN QUERY

    SELECT
        c.complaint_id,

        ROUND(
            ST_Distance(
                v_location::geography,
                l.geom::geography
            )::NUMERIC,
            2
        ) AS distance_meters,

        CASE

            -- Same category + extremely close
            WHEN c.category_id = v_category
                 AND ST_DWithin(
                     v_location::geography,
                     l.geom::geography,
                     50
                 )
            THEN 0.95

            -- Same category + nearby
            WHEN c.category_id = v_category
                 AND ST_DWithin(
                     v_location::geography,
                     l.geom::geography,
                     150
                 )
            THEN 0.80

            -- Different category but very close
            WHEN ST_DWithin(
                     v_location::geography,
                     l.geom::geography,
                     50
                 )
            THEN 0.60

            ELSE 0.20

        END AS similarity_score

    FROM complaints c

    JOIN locations l
        ON l.location_id = c.location_id

    WHERE c.complaint_id <> p_complaint_id

      AND c.status <> 'rejected'

      AND ST_DWithin(
          v_location::geography,
          l.geom::geography,
          500
      )

    ORDER BY similarity_score DESC;

END;
$$;


--
-- Name: detect_severity_mismatch(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.detect_severity_mismatch(p_complaint_id bigint) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE

    v_reported NUMERIC;
    v_ai NUMERIC;
    v_difference NUMERIC;

BEGIN

    SELECT
        COALESCE(c.reported_severity, 50),
        COALESCE(
            (
                SELECT estimated_severity
                FROM ai_analysis
                WHERE complaint_id = c.complaint_id
                ORDER BY analyzed_at DESC
                LIMIT 1
            ),
            50
        )

    INTO
        v_reported,
        v_ai

    FROM complaints c

    WHERE c.complaint_id = p_complaint_id;


    v_difference := ABS(v_reported - v_ai);


    -- Significant mismatch
    IF v_difference >= 40 THEN

        INSERT INTO fraud_flags
        (
            complaint_id,
            flag_type,
            confidence,
            reason
        )
        VALUES
        (
            p_complaint_id,
            'severity_mismatch',
            LEAST(v_difference / 100, 1),
            'Citizen-reported severity differs significantly from AI-estimated severity.'
        );

    END IF;


    RETURN v_difference;

END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ai_analysis; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_analysis (
    analysis_id bigint NOT NULL,
    complaint_id bigint NOT NULL,
    evidence_id bigint,
    model_name character varying(150),
    model_version character varying(100),
    detected_issue character varying(150),
    confidence_score numeric(6,5),
    estimated_severity numeric(5,2),
    estimated_size numeric(10,2),
    objects_detected jsonb DEFAULT '[]'::jsonb,
    analysis_result jsonb DEFAULT '{}'::jsonb,
    analyzed_at timestamp with time zone DEFAULT now()
);


--
-- Name: ai_analysis_analysis_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_analysis_analysis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_analysis_analysis_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ai_analysis_analysis_id_seq OWNED BY public.ai_analysis.analysis_id;


--
-- Name: assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignments (
    assignment_id bigint NOT NULL,
    complaint_id bigint NOT NULL,
    department_id bigint,
    assigned_to uuid,
    assigned_by uuid,
    assigned_at timestamp with time zone DEFAULT now(),
    deadline timestamp with time zone,
    accepted_at timestamp with time zone,
    completed_at timestamp with time zone,
    remarks text
);


--
-- Name: assignments_assignment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignments_assignment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignments_assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignments_assignment_id_seq OWNED BY public.assignments.assignment_id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    log_id bigint NOT NULL,
    profile_id uuid,
    action character varying(150) NOT NULL,
    entity_type character varying(100),
    entity_id bigint,
    old_value jsonb,
    new_value jsonb,
    ip_address inet,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: audit_logs_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_logs_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_logs_log_id_seq OWNED BY public.audit_logs.log_id;


--
-- Name: complaint_evidence; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.complaint_evidence (
    evidence_id bigint NOT NULL,
    complaint_id bigint NOT NULL,
    evidence_type public.evidence_type NOT NULL,
    file_url text NOT NULL,
    file_name character varying(255),
    capture_timestamp timestamp with time zone,
    latitude numeric(10,7),
    longitude numeric(10,7),
    uploaded_at timestamp with time zone DEFAULT now(),
    metadata jsonb DEFAULT '{}'::jsonb
);


--
-- Name: complaint_evidence_evidence_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.complaint_evidence_evidence_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: complaint_evidence_evidence_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.complaint_evidence_evidence_id_seq OWNED BY public.complaint_evidence.evidence_id;


--
-- Name: complaint_status_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.complaint_status_history (
    history_id bigint NOT NULL,
    complaint_id bigint NOT NULL,
    old_status public.complaint_status,
    new_status public.complaint_status NOT NULL,
    changed_by uuid,
    remarks text,
    changed_at timestamp with time zone DEFAULT now()
);


--
-- Name: complaint_status_history_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.complaint_status_history_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: complaint_status_history_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.complaint_status_history_history_id_seq OWNED BY public.complaint_status_history.history_id;


--
-- Name: complaints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.complaints (
    complaint_id bigint NOT NULL,
    profile_id uuid,
    category_id bigint NOT NULL,
    asset_id bigint,
    location_id bigint NOT NULL,
    title character varying(255) NOT NULL,
    description text NOT NULL,
    reported_severity numeric(5,2),
    reported_urgency numeric(5,2),
    status public.complaint_status DEFAULT 'submitted'::public.complaint_status,
    priority public.priority_level DEFAULT 'medium'::public.priority_level,
    source character varying(50) DEFAULT 'web'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    resolved_at timestamp with time zone
);


--
-- Name: complaints_complaint_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.complaints_complaint_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: complaints_complaint_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.complaints_complaint_id_seq OWNED BY public.complaints.complaint_id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departments (
    department_id bigint NOT NULL,
    department_name character varying(150) NOT NULL,
    description text,
    contact_email character varying(255),
    contact_phone character varying(30),
    created_at timestamp with time zone DEFAULT now(),
    is_active boolean DEFAULT true
);


--
-- Name: departments_department_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.departments_department_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: departments_department_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.departments_department_id_seq OWNED BY public.departments.department_id;


--
-- Name: duplicate_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.duplicate_reports (
    duplicate_id bigint NOT NULL,
    complaint_id bigint NOT NULL,
    possible_duplicate_id bigint NOT NULL,
    similarity_score numeric(6,5),
    distance_meters numeric(10,2),
    status character varying(50) DEFAULT 'pending'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT duplicate_reports_check CHECK ((complaint_id <> possible_duplicate_id))
);


--
-- Name: duplicate_reports_duplicate_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.duplicate_reports_duplicate_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: duplicate_reports_duplicate_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.duplicate_reports_duplicate_id_seq OWNED BY public.duplicate_reports.duplicate_id;


--
-- Name: escalations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.escalations (
    escalation_id bigint NOT NULL,
    complaint_id bigint NOT NULL,
    escalation_level integer DEFAULT 1 NOT NULL,
    reason text NOT NULL,
    escalated_to uuid,
    deadline timestamp with time zone,
    escalated_at timestamp with time zone DEFAULT now(),
    resolved_at timestamp with time zone
);


--
-- Name: escalations_escalation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.escalations_escalation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: escalations_escalation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.escalations_escalation_id_seq OWNED BY public.escalations.escalation_id;


--
-- Name: feedback; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feedback (
    feedback_id bigint NOT NULL,
    complaint_id bigint NOT NULL,
    profile_id uuid NOT NULL,
    rating integer,
    comment text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT feedback_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


--
-- Name: feedback_feedback_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feedback_feedback_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feedback_feedback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feedback_feedback_id_seq OWNED BY public.feedback.feedback_id;


--
-- Name: field_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.field_actions (
    action_id bigint NOT NULL,
    complaint_id bigint NOT NULL,
    worker_id uuid,
    action_type character varying(100) NOT NULL,
    description text,
    before_image_url text,
    after_image_url text,
    action_location public.geometry(Point,4326),
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: field_actions_action_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.field_actions_action_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: field_actions_action_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.field_actions_action_id_seq OWNED BY public.field_actions.action_id;


--
-- Name: fraud_flags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fraud_flags (
    flag_id bigint NOT NULL,
    complaint_id bigint NOT NULL,
    flag_type character varying(100) NOT NULL,
    confidence numeric(6,5),
    reason text,
    review_status character varying(50) DEFAULT 'pending'::character varying,
    reviewed_by uuid,
    reviewed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: fraud_flags_flag_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fraud_flags_flag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fraud_flags_flag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fraud_flags_flag_id_seq OWNED BY public.fraud_flags.flag_id;


--
-- Name: infrastructure_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.infrastructure_assets (
    asset_id bigint NOT NULL,
    asset_type character varying(100) NOT NULL,
    asset_name character varying(200),
    asset_code character varying(100),
    department_id bigint,
    ward_id bigint,
    location public.geometry(Point,4326),
    condition_score numeric(5,2),
    criticality_score numeric(5,2),
    installation_date date,
    last_inspection_date date,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: infrastructure_assets_asset_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.infrastructure_assets_asset_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: infrastructure_assets_asset_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.infrastructure_assets_asset_id_seq OWNED BY public.infrastructure_assets.asset_id;


--
-- Name: issue_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.issue_categories (
    category_id bigint NOT NULL,
    category_name character varying(100) NOT NULL,
    description text,
    default_department_id bigint,
    base_severity numeric(5,2) DEFAULT 50,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: issue_categories_category_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.issue_categories_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: issue_categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.issue_categories_category_id_seq OWNED BY public.issue_categories.category_id;


--
-- Name: locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locations (
    location_id bigint NOT NULL,
    latitude numeric(10,7) NOT NULL,
    longitude numeric(10,7) NOT NULL,
    geom public.geometry(Point,4326) NOT NULL,
    address text,
    landmark character varying(255),
    ward_id bigint,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: locations_location_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.locations_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: locations_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.locations_location_id_seq OWNED BY public.locations.location_id;


--
-- Name: nearby_sensitive_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nearby_sensitive_locations (
    sensitive_location_id bigint NOT NULL,
    name character varying(200) NOT NULL,
    type character varying(100) NOT NULL,
    importance_level numeric(5,2) DEFAULT 50,
    address text,
    geom public.geometry(Point,4326) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: nearby_sensitive_locations_sensitive_location_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nearby_sensitive_locations_sensitive_location_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nearby_sensitive_locations_sensitive_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nearby_sensitive_locations_sensitive_location_id_seq OWNED BY public.nearby_sensitive_locations.sensitive_location_id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    notification_id bigint NOT NULL,
    profile_id uuid NOT NULL,
    complaint_id bigint,
    notification_type character varying(100),
    message text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_notification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_notification_id_seq OWNED BY public.notifications.notification_id;


--
-- Name: priority_queue; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.priority_queue (
    queue_id bigint NOT NULL,
    complaint_id bigint NOT NULL,
    risk_score numeric(5,2) NOT NULL,
    priority public.priority_level NOT NULL,
    queue_position integer,
    entered_at timestamp with time zone DEFAULT now(),
    last_updated timestamp with time zone DEFAULT now()
);


--
-- Name: priority_queue_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.priority_queue_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: priority_queue_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.priority_queue_queue_id_seq OWNED BY public.priority_queue.queue_id;


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    profile_id uuid NOT NULL,
    full_name character varying(150) NOT NULL,
    phone character varying(30),
    role_id bigint,
    ward_id bigint,
    department_id bigint,
    address text,
    profile_image_url text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: risk_factors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.risk_factors (
    risk_factor_id bigint NOT NULL,
    risk_id bigint NOT NULL,
    factor_name character varying(100) NOT NULL,
    factor_value numeric(10,4),
    weight numeric(6,4),
    contribution numeric(10,4),
    explanation text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: risk_factors_risk_factor_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.risk_factors_risk_factor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: risk_factors_risk_factor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.risk_factors_risk_factor_id_seq OWNED BY public.risk_factors.risk_factor_id;


--
-- Name: risk_scores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.risk_scores (
    risk_id bigint NOT NULL,
    complaint_id bigint NOT NULL,
    severity_score numeric(5,2),
    location_score numeric(5,2),
    exposure_score numeric(5,2),
    infrastructure_score numeric(5,2),
    urgency_score numeric(5,2),
    evidence_score numeric(5,2),
    final_risk_score numeric(5,2) NOT NULL,
    priority public.priority_level NOT NULL,
    calculation_version character varying(50) DEFAULT '1.0'::character varying,
    calculated_at timestamp with time zone DEFAULT now()
);


--
-- Name: risk_scores_risk_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.risk_scores_risk_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: risk_scores_risk_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.risk_scores_risk_id_seq OWNED BY public.risk_scores.risk_id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    role_id bigint NOT NULL,
    role_name public.user_role NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: roles_role_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_role_id_seq OWNED BY public.roles.role_id;


--
-- Name: wards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wards (
    ward_id bigint NOT NULL,
    ward_number character varying(20) NOT NULL,
    ward_name character varying(150) NOT NULL,
    zone character varying(100),
    boundary_geometry public.geometry(MultiPolygon,4326),
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: wards_ward_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wards_ward_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wards_ward_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wards_ward_id_seq OWNED BY public.wards.ward_id;


--
-- Name: ai_analysis analysis_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_analysis ALTER COLUMN analysis_id SET DEFAULT nextval('public.ai_analysis_analysis_id_seq'::regclass);


--
-- Name: assignments assignment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments ALTER COLUMN assignment_id SET DEFAULT nextval('public.assignments_assignment_id_seq'::regclass);


--
-- Name: audit_logs log_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN log_id SET DEFAULT nextval('public.audit_logs_log_id_seq'::regclass);


--
-- Name: complaint_evidence evidence_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaint_evidence ALTER COLUMN evidence_id SET DEFAULT nextval('public.complaint_evidence_evidence_id_seq'::regclass);


--
-- Name: complaint_status_history history_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaint_status_history ALTER COLUMN history_id SET DEFAULT nextval('public.complaint_status_history_history_id_seq'::regclass);


--
-- Name: complaints complaint_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaints ALTER COLUMN complaint_id SET DEFAULT nextval('public.complaints_complaint_id_seq'::regclass);


--
-- Name: departments department_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments ALTER COLUMN department_id SET DEFAULT nextval('public.departments_department_id_seq'::regclass);


--
-- Name: duplicate_reports duplicate_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.duplicate_reports ALTER COLUMN duplicate_id SET DEFAULT nextval('public.duplicate_reports_duplicate_id_seq'::regclass);


--
-- Name: escalations escalation_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escalations ALTER COLUMN escalation_id SET DEFAULT nextval('public.escalations_escalation_id_seq'::regclass);


--
-- Name: feedback feedback_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback ALTER COLUMN feedback_id SET DEFAULT nextval('public.feedback_feedback_id_seq'::regclass);


--
-- Name: field_actions action_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.field_actions ALTER COLUMN action_id SET DEFAULT nextval('public.field_actions_action_id_seq'::regclass);


--
-- Name: fraud_flags flag_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fraud_flags ALTER COLUMN flag_id SET DEFAULT nextval('public.fraud_flags_flag_id_seq'::regclass);


--
-- Name: infrastructure_assets asset_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.infrastructure_assets ALTER COLUMN asset_id SET DEFAULT nextval('public.infrastructure_assets_asset_id_seq'::regclass);


--
-- Name: issue_categories category_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_categories ALTER COLUMN category_id SET DEFAULT nextval('public.issue_categories_category_id_seq'::regclass);


--
-- Name: locations location_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations ALTER COLUMN location_id SET DEFAULT nextval('public.locations_location_id_seq'::regclass);


--
-- Name: nearby_sensitive_locations sensitive_location_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nearby_sensitive_locations ALTER COLUMN sensitive_location_id SET DEFAULT nextval('public.nearby_sensitive_locations_sensitive_location_id_seq'::regclass);


--
-- Name: notifications notification_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN notification_id SET DEFAULT nextval('public.notifications_notification_id_seq'::regclass);


--
-- Name: priority_queue queue_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.priority_queue ALTER COLUMN queue_id SET DEFAULT nextval('public.priority_queue_queue_id_seq'::regclass);


--
-- Name: risk_factors risk_factor_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_factors ALTER COLUMN risk_factor_id SET DEFAULT nextval('public.risk_factors_risk_factor_id_seq'::regclass);


--
-- Name: risk_scores risk_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_scores ALTER COLUMN risk_id SET DEFAULT nextval('public.risk_scores_risk_id_seq'::regclass);


--
-- Name: roles role_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN role_id SET DEFAULT nextval('public.roles_role_id_seq'::regclass);


--
-- Name: wards ward_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wards ALTER COLUMN ward_id SET DEFAULT nextval('public.wards_ward_id_seq'::regclass);


--
-- Name: ai_analysis ai_analysis_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_analysis
    ADD CONSTRAINT ai_analysis_pkey PRIMARY KEY (analysis_id);


--
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (assignment_id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (log_id);


--
-- Name: complaint_evidence complaint_evidence_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaint_evidence
    ADD CONSTRAINT complaint_evidence_pkey PRIMARY KEY (evidence_id);


--
-- Name: complaint_status_history complaint_status_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaint_status_history
    ADD CONSTRAINT complaint_status_history_pkey PRIMARY KEY (history_id);


--
-- Name: complaints complaints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_pkey PRIMARY KEY (complaint_id);


--
-- Name: departments departments_department_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_department_name_key UNIQUE (department_name);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (department_id);


--
-- Name: duplicate_reports duplicate_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.duplicate_reports
    ADD CONSTRAINT duplicate_reports_pkey PRIMARY KEY (duplicate_id);


--
-- Name: escalations escalations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escalations
    ADD CONSTRAINT escalations_pkey PRIMARY KEY (escalation_id);


--
-- Name: feedback feedback_complaint_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_complaint_id_key UNIQUE (complaint_id);


--
-- Name: feedback feedback_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY (feedback_id);


--
-- Name: field_actions field_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.field_actions
    ADD CONSTRAINT field_actions_pkey PRIMARY KEY (action_id);


--
-- Name: fraud_flags fraud_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fraud_flags
    ADD CONSTRAINT fraud_flags_pkey PRIMARY KEY (flag_id);


--
-- Name: infrastructure_assets infrastructure_assets_asset_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.infrastructure_assets
    ADD CONSTRAINT infrastructure_assets_asset_code_key UNIQUE (asset_code);


--
-- Name: infrastructure_assets infrastructure_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.infrastructure_assets
    ADD CONSTRAINT infrastructure_assets_pkey PRIMARY KEY (asset_id);


--
-- Name: issue_categories issue_categories_category_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_categories
    ADD CONSTRAINT issue_categories_category_name_key UNIQUE (category_name);


--
-- Name: issue_categories issue_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_categories
    ADD CONSTRAINT issue_categories_pkey PRIMARY KEY (category_id);


--
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (location_id);


--
-- Name: nearby_sensitive_locations nearby_sensitive_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nearby_sensitive_locations
    ADD CONSTRAINT nearby_sensitive_locations_pkey PRIMARY KEY (sensitive_location_id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);


--
-- Name: priority_queue priority_queue_complaint_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.priority_queue
    ADD CONSTRAINT priority_queue_complaint_id_key UNIQUE (complaint_id);


--
-- Name: priority_queue priority_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.priority_queue
    ADD CONSTRAINT priority_queue_pkey PRIMARY KEY (queue_id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (profile_id);


--
-- Name: risk_factors risk_factors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_factors
    ADD CONSTRAINT risk_factors_pkey PRIMARY KEY (risk_factor_id);


--
-- Name: risk_scores risk_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_scores
    ADD CONSTRAINT risk_scores_pkey PRIMARY KEY (risk_id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- Name: roles roles_role_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_role_name_key UNIQUE (role_name);


--
-- Name: wards wards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wards
    ADD CONSTRAINT wards_pkey PRIMARY KEY (ward_id);


--
-- Name: wards wards_ward_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wards
    ADD CONSTRAINT wards_ward_number_key UNIQUE (ward_number);


--
-- Name: idx_assets_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assets_location ON public.infrastructure_assets USING gist (location);


--
-- Name: idx_complaints_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_complaints_category ON public.complaints USING btree (category_id);


--
-- Name: idx_complaints_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_complaints_created ON public.complaints USING btree (created_at);


--
-- Name: idx_complaints_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_complaints_priority ON public.complaints USING btree (priority);


--
-- Name: idx_complaints_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_complaints_status ON public.complaints USING btree (status);


--
-- Name: idx_field_action_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_field_action_location ON public.field_actions USING gist (action_location);


--
-- Name: idx_locations_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_locations_geom ON public.locations USING gist (geom);


--
-- Name: idx_priority_queue_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_priority_queue_score ON public.priority_queue USING btree (risk_score DESC);


--
-- Name: idx_risk_final_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_risk_final_score ON public.risk_scores USING btree (final_risk_score DESC);


--
-- Name: idx_sensitive_location_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sensitive_location_geom ON public.nearby_sensitive_locations USING gist (geom);


--
-- Name: idx_wards_boundary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wards_boundary ON public.wards USING gist (boundary_geometry);


--
-- Name: ai_analysis ai_analysis_complaint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_analysis
    ADD CONSTRAINT ai_analysis_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES public.complaints(complaint_id) ON DELETE CASCADE;


--
-- Name: ai_analysis ai_analysis_evidence_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_analysis
    ADD CONSTRAINT ai_analysis_evidence_id_fkey FOREIGN KEY (evidence_id) REFERENCES public.complaint_evidence(evidence_id) ON DELETE SET NULL;


--
-- Name: assignments assignments_assigned_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.profiles(profile_id);


--
-- Name: assignments assignments_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.profiles(profile_id);


--
-- Name: assignments assignments_complaint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES public.complaints(complaint_id) ON DELETE CASCADE;


--
-- Name: assignments assignments_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- Name: audit_logs audit_logs_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(profile_id);


--
-- Name: complaint_evidence complaint_evidence_complaint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaint_evidence
    ADD CONSTRAINT complaint_evidence_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES public.complaints(complaint_id) ON DELETE CASCADE;


--
-- Name: complaint_status_history complaint_status_history_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaint_status_history
    ADD CONSTRAINT complaint_status_history_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.profiles(profile_id);


--
-- Name: complaint_status_history complaint_status_history_complaint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaint_status_history
    ADD CONSTRAINT complaint_status_history_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES public.complaints(complaint_id) ON DELETE CASCADE;


--
-- Name: complaints complaints_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.infrastructure_assets(asset_id);


--
-- Name: complaints complaints_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.issue_categories(category_id);


--
-- Name: complaints complaints_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.locations(location_id);


--
-- Name: complaints complaints_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.complaints
    ADD CONSTRAINT complaints_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(profile_id);


--
-- Name: duplicate_reports duplicate_reports_complaint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.duplicate_reports
    ADD CONSTRAINT duplicate_reports_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES public.complaints(complaint_id) ON DELETE CASCADE;


--
-- Name: duplicate_reports duplicate_reports_possible_duplicate_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.duplicate_reports
    ADD CONSTRAINT duplicate_reports_possible_duplicate_id_fkey FOREIGN KEY (possible_duplicate_id) REFERENCES public.complaints(complaint_id) ON DELETE CASCADE;


--
-- Name: escalations escalations_complaint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escalations
    ADD CONSTRAINT escalations_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES public.complaints(complaint_id) ON DELETE CASCADE;


--
-- Name: escalations escalations_escalated_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.escalations
    ADD CONSTRAINT escalations_escalated_to_fkey FOREIGN KEY (escalated_to) REFERENCES public.profiles(profile_id);


--
-- Name: feedback feedback_complaint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES public.complaints(complaint_id) ON DELETE CASCADE;


--
-- Name: feedback feedback_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feedback
    ADD CONSTRAINT feedback_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(profile_id);


--
-- Name: field_actions field_actions_complaint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.field_actions
    ADD CONSTRAINT field_actions_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES public.complaints(complaint_id) ON DELETE CASCADE;


--
-- Name: field_actions field_actions_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.field_actions
    ADD CONSTRAINT field_actions_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES public.profiles(profile_id);


--
-- Name: fraud_flags fraud_flags_complaint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fraud_flags
    ADD CONSTRAINT fraud_flags_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES public.complaints(complaint_id) ON DELETE CASCADE;


--
-- Name: fraud_flags fraud_flags_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fraud_flags
    ADD CONSTRAINT fraud_flags_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.profiles(profile_id);


--
-- Name: infrastructure_assets infrastructure_assets_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.infrastructure_assets
    ADD CONSTRAINT infrastructure_assets_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- Name: infrastructure_assets infrastructure_assets_ward_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.infrastructure_assets
    ADD CONSTRAINT infrastructure_assets_ward_id_fkey FOREIGN KEY (ward_id) REFERENCES public.wards(ward_id);


--
-- Name: issue_categories issue_categories_default_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.issue_categories
    ADD CONSTRAINT issue_categories_default_department_id_fkey FOREIGN KEY (default_department_id) REFERENCES public.departments(department_id);


--
-- Name: locations locations_ward_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_ward_id_fkey FOREIGN KEY (ward_id) REFERENCES public.wards(ward_id);


--
-- Name: notifications notifications_complaint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES public.complaints(complaint_id) ON DELETE CASCADE;


--
-- Name: notifications notifications_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(profile_id) ON DELETE CASCADE;


--
-- Name: priority_queue priority_queue_complaint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.priority_queue
    ADD CONSTRAINT priority_queue_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES public.complaints(complaint_id) ON DELETE CASCADE;


--
-- Name: profiles profiles_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- Name: profiles profiles_profile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id);


--
-- Name: profiles profiles_ward_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_ward_id_fkey FOREIGN KEY (ward_id) REFERENCES public.wards(ward_id);


--
-- Name: risk_factors risk_factors_risk_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_factors
    ADD CONSTRAINT risk_factors_risk_id_fkey FOREIGN KEY (risk_id) REFERENCES public.risk_scores(risk_id) ON DELETE CASCADE;


--
-- Name: risk_scores risk_scores_complaint_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.risk_scores
    ADD CONSTRAINT risk_scores_complaint_id_fkey FOREIGN KEY (complaint_id) REFERENCES public.complaints(complaint_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict px8eLKLp5DzVMR8SjV0fSGQ5vx4Q0sRdwVxJZNMohcI7yfQ74MyzhB5fGduH61r

