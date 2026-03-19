-- Job Hunt Tracker Database Schema for Supabase

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- COMPANIES
-- =============================================
CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    website TEXT,
    industry TEXT,
    size TEXT,
    location TEXT,
    linkedin_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- APPLICATIONS
-- =============================================
CREATE TABLE IF NOT EXISTS applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Job Info
    job_title TEXT NOT NULL,
    company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
    company_name TEXT NOT NULL, -- denormalized for easier queries
    
    -- Platform & Source
    platform TEXT NOT NULL, -- LinkedIn, Indeed, Direct, ApplyPilot, etc.
    application_url TEXT,
    source_notes TEXT, -- "Found via LinkedIn recruiter"
    
    -- Application Details
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'applied' CHECK (status IN (
        'applied', 'not_applied', 'viewed', 'interview', 'offer', 
        'rejected', 'withdrawn', 'expired'
    )),
    
    -- Materials
    resume_used TEXT,
    cover_letter TEXT,
    
    -- Salary
    salary_range_min INTEGER,
    salary_range_max INTEGER,
    salary_currency TEXT DEFAULT 'USD',
    
    -- Notes
    notes TEXT,
    
    -- Tracking
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for common queries
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);
CREATE INDEX IF NOT EXISTS idx_applications_platform ON applications(platform);
CREATE INDEX IF NOT EXISTS idx_applications_applied_at ON applications(applied_at DESC);

-- =============================================
-- CONTACTS
-- =============================================
CREATE TABLE IF NOT EXISTS contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Link to application (optional)
    application_id UUID REFERENCES applications(id) ON DELETE SET NULL,
    
    -- Contact Info
    name TEXT NOT NULL,
    email TEXT,
    role TEXT, -- Recruiter, Hiring Manager, HR, etc.
    linkedin_url TEXT,
    
    -- Source of this contact
    source TEXT, -- direct_email, linkedin, referral, company_website
    
    -- Notes
    notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_contacts_application_id ON contacts(application_id);

-- =============================================
-- FOLLOW_UPS
-- =============================================
CREATE TABLE IF NOT EXISTS follow_ups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Link to application or contact
    application_id UUID REFERENCES applications(id) ON DELETE CASCADE,
    contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
    
    -- Follow-up Details
    follow_up_date DATE NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'replied', 'bounced', 'cancelled')),
    
    -- Content
    subject TEXT,
    body TEXT,
    sent_at TIMESTAMPTZ,
    
    -- Response
    reply_received_at TIMESTAMPTZ,
    reply_body TEXT,
    
    -- Notes
    notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_follow_ups_follow_up_date ON follow_ups(follow_up_date);
CREATE INDEX IF NOT EXISTS idx_follow_ups_status ON follow_ups(status);

-- =============================================
-- EMAIL_TRACKING (for Gmail integration)
-- =============================================
CREATE TABLE IF NOT EXISTS email_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Link to application if applicable
    application_id UUID REFERENCES applications(id) ON DELETE SET NULL,
    
    -- Email Details
    email_from TEXT NOT NULL, -- full email or domain
    email_to TEXT NOT NULL,
    subject TEXT,
    received_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Direction
    direction TEXT CHECK (direction IN ('inbound', 'outbound')),
    
    -- Parsed Content
    body_text TEXT,
    body_html TEXT,
    
    -- Labels (from Gmail)
    gmail_labels TEXT[],
    
    -- Read status
    is_read BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_email_tracking_application_id ON email_tracking(application_id);
CREATE INDEX IF NOT EXISTS idx_email_tracking_received_at ON email_tracking(received_at DESC);

-- =============================================
-- ACTIVITY_LOG
-- =============================================
CREATE TABLE IF NOT EXISTS activity_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- What happened
    action TEXT NULL, -- 'applied', 'not_applied', 'email_sent', 'follow_up', 'status_changed', etc.
    
    -- References
    application_id UUID REFERENCES applications(id) ON DELETE CASCADE,
    contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
    
    -- Details
    details JSONB DEFAULT '{}',
    notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activity_log_application_id ON activity_log(application_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_created_at ON activity_log(created_at DESC);

-- =============================================
-- SKILL_CONFIG
-- =============================================
CREATE TABLE IF NOT EXISTS skill_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Skill identifier
    skill_name TEXT NOT NULL UNIQUE, -- 'linkedin-auto-applier', 'applypilot'
    
    -- Config
    config JSONB DEFAULT '{}',
    env_vars JSONB DEFAULT '{}', -- encrypted in production
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    last_run_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- APPLYPILOT
-- =============================================
-- Lightweight sync table: ApplyPilot writes job outcomes here after each
-- apply run. CRM agent picks these up for follow-ups and tracking.
-- Upserted by applypilot on every apply cycle (keyed on url).
CREATE TABLE IF NOT EXISTS applypilot (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Core job info
    url TEXT UNIQUE NOT NULL,
    title TEXT,
    company_name TEXT,
    location TEXT,
    site TEXT, -- Indeed, LinkedIn, etc.

    -- AI scoring from ApplyPilot
    fit_score INTEGER,
    score_reasoning TEXT,

    -- Apply outcome
    applied_at TIMESTAMPTZ,
    apply_status TEXT DEFAULT 'applied' CHECK (apply_status IN (
        'applied', 'success', 'failed', 'rejected', 'blocked'
    )),
    apply_error TEXT,
    apply_attempts INTEGER DEFAULT 0,

    -- Materials generated
    tailored_resume_path TEXT,
    cover_letter_path TEXT,

    -- Tracking
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_applypilot_url ON applypilot(url);
CREATE INDEX IF NOT EXISTS idx_applypilot_applied_at ON applypilot(applied_at DESC);
CREATE INDEX IF NOT EXISTS idx_applypilot_apply_status ON applypilot(apply_status);

-- =============================================
-- VIEWS
-- =============================================

-- Dashboard view
DROP VIEW IF EXISTS dashboard_stats;
CREATE OR REPLACE VIEW dashboard_stats AS
SELECT 
    COUNT(*) as total_applications,
    COUNT(*) FILTER (WHERE status = 'applied') as applied,
    COUNT(*) FILTER (WHERE status = 'not_applied') as not_applied,
    COUNT(*) FILTER (WHERE status = 'viewed') as viewed,
    COUNT(*) FILTER (WHERE status = 'interview') as interview,
    COUNT(*) FILTER (WHERE status = 'offer') as offer,
    COUNT(*) FILTER (WHERE status = 'rejected') as rejected,
    COUNT(*) FILTER (WHERE status = 'withdrawn') as withdrawn
FROM applications;

-- Applications with contacts
DROP VIEW IF EXISTS applications_with_contacts;
CREATE OR REPLACE VIEW applications_with_contacts AS
SELECT 
    a.*,
    COALESCE(
        json_agg(
            json_build_object(
                'name', c.name,
                'email', c.email,
                'role', c.role
            )
        ) FILTER (WHERE c.id IS NOT NULL),
        '[]'::json
    ) as contacts
FROM applications a
LEFT JOIN contacts c ON c.application_id = a.id
GROUP BY a.id;

-- =============================================
-- FUNCTIONS
-- =============================================

-- Update updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables
DROP TRIGGER IF EXISTS update_companies_updated_at ON companies;
CREATE OR REPLACE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_applications_updated_at ON applications;
CREATE OR REPLACE TRIGGER update_applications_updated_at BEFORE UPDATE ON applications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_contacts_updated_at ON contacts;
CREATE OR REPLACE TRIGGER update_contacts_updated_at BEFORE UPDATE ON contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_skill_config_updated_at ON skill_config;
CREATE OR REPLACE TRIGGER update_skill_config_updated_at BEFORE UPDATE ON skill_config
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================
-- ROW LEVEL SECURITY
-- =============================================

-- Enable RLS only if not already enabled (safe to run on existing tables)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'companies' AND rowsecurity) THEN
    ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'applications' AND rowsecurity) THEN
    ALTER TABLE applications ENABLE ROW LEVEL SECURITY;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'contacts' AND rowsecurity) THEN
    ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'follow_ups' AND rowsecurity) THEN
    ALTER TABLE follow_ups ENABLE ROW LEVEL SECURITY;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'email_tracking' AND rowsecurity) THEN
    ALTER TABLE email_tracking ENABLE ROW LEVEL SECURITY;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'activity_log' AND rowsecurity) THEN
    ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'skill_config' AND rowsecurity) THEN
    ALTER TABLE skill_config ENABLE ROW LEVEL SECURITY;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'applypilot' AND rowsecurity) THEN
    ALTER TABLE applypilot ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Allow all access for now (single user)
DO $$
DECLARE
  _policy_count integer;
BEGIN
  -- Check and create for each table using a simple approach
  SELECT COUNT(*) INTO _policy_count FROM pg_policies WHERE policyname = 'Allow all access' AND tablename = 'companies';
  IF _policy_count = 0 THEN
    CREATE POLICY "Allow all access" ON companies FOR ALL USING (TRUE);
  END IF;

  SELECT COUNT(*) INTO _policy_count FROM pg_policies WHERE policyname = 'Allow all access' AND tablename = 'applications';
  IF _policy_count = 0 THEN
    CREATE POLICY "Allow all access" ON applications FOR ALL USING (TRUE);
  END IF;

  SELECT COUNT(*) INTO _policy_count FROM pg_policies WHERE policyname = 'Allow all access' AND tablename = 'contacts';
  IF _policy_count = 0 THEN
    CREATE POLICY "Allow all access" ON contacts FOR ALL USING (TRUE);
  END IF;

  SELECT COUNT(*) INTO _policy_count FROM pg_policies WHERE policyname = 'Allow all access' AND tablename = 'follow_ups';
  IF _policy_count = 0 THEN
    CREATE POLICY "Allow all access" ON follow_ups FOR ALL USING (TRUE);
  END IF;

  SELECT COUNT(*) INTO _policy_count FROM pg_policies WHERE policyname = 'Allow all access' AND tablename = 'email_tracking';
  IF _policy_count = 0 THEN
    CREATE POLICY "Allow all access" ON email_tracking FOR ALL USING (TRUE);
  END IF;

  SELECT COUNT(*) INTO _policy_count FROM pg_policies WHERE policyname = 'Allow all access' AND tablename = 'activity_log';
  IF _policy_count = 0 THEN
    CREATE POLICY "Allow all access" ON activity_log FOR ALL USING (TRUE);
  END IF;

  SELECT COUNT(*) INTO _policy_count FROM pg_policies WHERE policyname = 'Allow all access' AND tablename = 'skill_config';
  IF _policy_count = 0 THEN
    CREATE POLICY "Allow all access" ON skill_config FOR ALL USING (TRUE);
  END IF;

  SELECT COUNT(*) INTO _policy_count FROM pg_policies WHERE policyname = 'Allow all access' AND tablename = 'applypilot';
  IF _policy_count = 0 THEN
    CREATE POLICY "Allow all access" ON applypilot FOR ALL USING (TRUE);
  END IF;
END $$;

DROP TRIGGER IF EXISTS update_applypilot_updated_at ON applypilot;
CREATE OR REPLACE TRIGGER update_applypilot_updated_at BEFORE UPDATE ON applypilot
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
