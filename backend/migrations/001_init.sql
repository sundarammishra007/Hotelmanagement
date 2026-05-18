-- =============================================================================
-- File: 001_init.sql
-- Hotel Management System — Initial Schema
-- PostgreSQL 14+
-- =============================================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- =============================================================================
-- ENUM TYPES
-- =============================================================================

CREATE TYPE room_status AS ENUM (
    'available',
    'occupied',
    'cleaning',
    'maintenance'
);

CREATE TYPE room_type AS ENUM (
    'single',
    'double',
    'suite',
    'deluxe'
);

CREATE TYPE user_role AS ENUM (
    'admin',
    'manager',
    'receptionist',
    'housekeeping'
);

CREATE TYPE payment_method AS ENUM (
    'cash',
    'upi',
    'card'
);

CREATE TYPE payment_status AS ENUM (
    'pending',
    'partial',
    'paid',
    'refunded'
);

CREATE TYPE id_proof_type AS ENUM (
    'aadhar',
    'passport',
    'driving_license',
    'voter_id'
);

CREATE TYPE attendance_status AS ENUM (
    'present',
    'absent',
    'leave'
);

CREATE TYPE checkin_status AS ENUM (
    'active',
    'checked_out',
    'cancelled'
);

CREATE TYPE shift_type AS ENUM (
    'morning',
    'evening',
    'night'
);


-- =============================================================================
-- SEQUENCES
-- =============================================================================

-- Sequence for invoice number generation (padded 4-digit counter per year)
CREATE SEQUENCE IF NOT EXISTS invoice_number_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    CACHE 1;


-- =============================================================================
-- TABLE: users
-- =============================================================================

CREATE TABLE users (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(150)    NOT NULL,
    email           VARCHAR(255)    NOT NULL,
    password_hash   TEXT            NOT NULL,
    role            user_role       NOT NULL DEFAULT 'receptionist',
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT users_email_unique UNIQUE (email),
    CONSTRAINT users_name_not_empty CHECK (TRIM(name) <> ''),
    CONSTRAINT users_email_format  CHECK (email ~* '^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$')
);

COMMENT ON TABLE  users              IS 'System users who can log in to the hotel management portal';
COMMENT ON COLUMN users.password_hash IS 'bcrypt / argon2 hash — never store plaintext';


-- =============================================================================
-- TABLE: staff
-- =============================================================================

CREATE TABLE staff (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL,
    employee_id     VARCHAR(50)     NOT NULL,
    phone           VARCHAR(20)     NOT NULL,
    address         TEXT,
    joining_date    DATE            NOT NULL DEFAULT CURRENT_DATE,
    department      VARCHAR(100)    NOT NULL,
    shift           shift_type      NOT NULL DEFAULT 'morning',
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT staff_user_id_fk         FOREIGN KEY (user_id)
                                            REFERENCES users (id)
                                            ON UPDATE CASCADE
                                            ON DELETE RESTRICT,
    CONSTRAINT staff_employee_id_unique UNIQUE (employee_id),
    CONSTRAINT staff_user_id_unique     UNIQUE (user_id),          -- one staff record per user
    CONSTRAINT staff_phone_not_empty    CHECK (TRIM(phone) <> ''),
    CONSTRAINT staff_dept_not_empty     CHECK (TRIM(department) <> '')
);

COMMENT ON TABLE staff IS 'Extended profile for hotel staff members (linked to users)';


-- =============================================================================
-- TABLE: staff_attendance
-- =============================================================================

CREATE TABLE staff_attendance (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id        UUID            NOT NULL,
    date            DATE            NOT NULL,
    check_in_time   TIME,
    check_out_time  TIME,
    status          attendance_status NOT NULL DEFAULT 'present',
    notes           TEXT,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT staff_attendance_staff_fk    FOREIGN KEY (staff_id)
                                                REFERENCES staff (id)
                                                ON UPDATE CASCADE
                                                ON DELETE CASCADE,
    CONSTRAINT staff_attendance_unique_day  UNIQUE (staff_id, date),
    CONSTRAINT attendance_checkout_after_checkin
        CHECK (check_out_time IS NULL OR check_in_time IS NULL OR check_out_time > check_in_time)
);

COMMENT ON TABLE staff_attendance IS 'Daily attendance records for hotel staff';


-- =============================================================================
-- TABLE: rooms
-- =============================================================================

CREATE TABLE rooms (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    room_number     VARCHAR(20)     NOT NULL,
    floor           SMALLINT        NOT NULL,
    room_type       room_type       NOT NULL,
    status          room_status     NOT NULL DEFAULT 'available',
    price_per_night DECIMAL(10, 2)  NOT NULL,
    amenities       TEXT[]          NOT NULL DEFAULT '{}',
    description     TEXT,
    max_occupancy   SMALLINT        NOT NULL DEFAULT 2,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT rooms_room_number_unique     UNIQUE (room_number),
    CONSTRAINT rooms_price_positive         CHECK (price_per_night > 0),
    CONSTRAINT rooms_floor_positive         CHECK (floor >= 0),
    CONSTRAINT rooms_max_occupancy_positive CHECK (max_occupancy > 0)
);

COMMENT ON TABLE  rooms                   IS 'Physical rooms available in the hotel';
COMMENT ON COLUMN rooms.amenities         IS 'Array of amenity strings, e.g. {wifi, ac, tv, minibar}';
COMMENT ON COLUMN rooms.price_per_night   IS 'Base price in INR per night';


-- =============================================================================
-- TABLE: guests
-- =============================================================================

CREATE TABLE guests (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(150)    NOT NULL,
    email               VARCHAR(255),
    phone               VARCHAR(20)     NOT NULL,
    address             TEXT,
    id_proof_type       id_proof_type,
    id_proof_number     VARCHAR(100),
    id_proof_image_url  TEXT,           -- Cloudinary CDN URL
    nationality         VARCHAR(100)    NOT NULL DEFAULT 'Indian',
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT guests_name_not_empty    CHECK (TRIM(name) <> ''),
    CONSTRAINT guests_phone_not_empty   CHECK (TRIM(phone) <> ''),
    CONSTRAINT guests_email_format      CHECK (
        email IS NULL OR
        email ~* '^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$'
    ),
    CONSTRAINT guests_id_proof_pair     CHECK (
        (id_proof_type IS NULL AND id_proof_number IS NULL) OR
        (id_proof_type IS NOT NULL AND id_proof_number IS NOT NULL)
    )
);

COMMENT ON TABLE  guests                    IS 'Hotel guests — may stay multiple times';
COMMENT ON COLUMN guests.id_proof_image_url IS 'Full Cloudinary URL to the uploaded ID document image';


-- =============================================================================
-- TABLE: checkins
-- =============================================================================

CREATE TABLE checkins (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    guest_id            UUID            NOT NULL,
    room_id             UUID            NOT NULL,
    checked_in_by       UUID            NOT NULL,
    check_in_date       TIMESTAMPTZ     NOT NULL,
    check_out_date      TIMESTAMPTZ,                -- expected checkout
    actual_checkout     TIMESTAMPTZ,                -- actual checkout timestamp
    adults              SMALLINT        NOT NULL DEFAULT 1,
    children            SMALLINT        NOT NULL DEFAULT 0,
    special_requests    TEXT,
    status              checkin_status  NOT NULL DEFAULT 'active',
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT checkins_guest_fk        FOREIGN KEY (guest_id)
                                            REFERENCES guests (id)
                                            ON UPDATE CASCADE
                                            ON DELETE RESTRICT,
    CONSTRAINT checkins_room_fk         FOREIGN KEY (room_id)
                                            REFERENCES rooms (id)
                                            ON UPDATE CASCADE
                                            ON DELETE RESTRICT,
    CONSTRAINT checkins_user_fk         FOREIGN KEY (checked_in_by)
                                            REFERENCES users (id)
                                            ON UPDATE CASCADE
                                            ON DELETE RESTRICT,
    CONSTRAINT checkins_adults_positive     CHECK (adults > 0),
    CONSTRAINT checkins_children_nonneg    CHECK (children >= 0),
    CONSTRAINT checkins_checkout_after_checkin
        CHECK (check_out_date IS NULL OR check_out_date > check_in_date),
    CONSTRAINT checkins_actual_after_checkin
        CHECK (actual_checkout IS NULL OR actual_checkout >= check_in_date)
);

COMMENT ON TABLE  checkins              IS 'Guest check-in records — one row per stay';
COMMENT ON COLUMN checkins.check_out_date  IS 'Expected / planned checkout date';
COMMENT ON COLUMN checkins.actual_checkout IS 'Actual time guest checked out';


-- =============================================================================
-- TABLE: invoices
-- =============================================================================

CREATE TABLE invoices (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    checkin_id      UUID            NOT NULL,
    invoice_number  VARCHAR(20)     NOT NULL,
    guest_id        UUID            NOT NULL,
    room_charges    DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    extra_charges   DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    discount        DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    subtotal        DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    cgst_rate       DECIMAL(5, 2)   NOT NULL DEFAULT 9,     -- 9 %
    sgst_rate       DECIMAL(5, 2)   NOT NULL DEFAULT 9,     -- 9 %
    cgst_amount     DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    sgst_amount     DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    total_amount    DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    payment_status  payment_status  NOT NULL DEFAULT 'pending',
    notes           TEXT,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT invoices_checkin_fk          FOREIGN KEY (checkin_id)
                                                REFERENCES checkins (id)
                                                ON UPDATE CASCADE
                                                ON DELETE RESTRICT,
    CONSTRAINT invoices_guest_fk            FOREIGN KEY (guest_id)
                                                REFERENCES guests (id)
                                                ON UPDATE CASCADE
                                                ON DELETE RESTRICT,
    CONSTRAINT invoices_checkin_unique      UNIQUE (checkin_id),
    CONSTRAINT invoices_number_unique       UNIQUE (invoice_number),
    CONSTRAINT invoices_room_charges_nonneg CHECK (room_charges >= 0),
    CONSTRAINT invoices_extra_charges_nonneg CHECK (extra_charges >= 0),
    CONSTRAINT invoices_discount_nonneg     CHECK (discount >= 0),
    CONSTRAINT invoices_total_nonneg        CHECK (total_amount >= 0),
    CONSTRAINT invoices_cgst_rate_range     CHECK (cgst_rate BETWEEN 0 AND 100),
    CONSTRAINT invoices_sgst_rate_range     CHECK (sgst_rate BETWEEN 0 AND 100)
);

COMMENT ON TABLE  invoices              IS 'One invoice per check-in stay';
COMMENT ON COLUMN invoices.cgst_rate    IS 'Central GST rate in percent (default 9%)';
COMMENT ON COLUMN invoices.sgst_rate    IS 'State GST rate in percent (default 9%)';


-- =============================================================================
-- TABLE: payments
-- =============================================================================

CREATE TABLE payments (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id      UUID            NOT NULL,
    amount          DECIMAL(12, 2)  NOT NULL,
    payment_method  payment_method  NOT NULL,
    transaction_id  VARCHAR(255),               -- UPI ref / card auth code / receipt no.
    paid_at         TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    received_by     UUID            NOT NULL,
    notes           TEXT,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT payments_invoice_fk      FOREIGN KEY (invoice_id)
                                            REFERENCES invoices (id)
                                            ON UPDATE CASCADE
                                            ON DELETE RESTRICT,
    CONSTRAINT payments_user_fk         FOREIGN KEY (received_by)
                                            REFERENCES users (id)
                                            ON UPDATE CASCADE
                                            ON DELETE RESTRICT,
    CONSTRAINT payments_amount_positive CHECK (amount > 0)
);

COMMENT ON TABLE  payments              IS 'Individual payment transactions against an invoice';
COMMENT ON COLUMN payments.transaction_id IS 'External reference: UPI UTR, card auth code, or cash receipt number';


-- =============================================================================
-- INDEXES
-- =============================================================================

-- checkins
CREATE INDEX idx_checkins_guest_id  ON checkins (guest_id);
CREATE INDEX idx_checkins_room_id   ON checkins (room_id);
CREATE INDEX idx_checkins_status    ON checkins (status);
CREATE INDEX idx_checkins_dates     ON checkins (check_in_date, check_out_date);

-- invoices
CREATE INDEX idx_invoices_invoice_number    ON invoices (invoice_number);
CREATE INDEX idx_invoices_payment_status    ON invoices (payment_status);
CREATE INDEX idx_invoices_guest_id          ON invoices (guest_id);

-- payments
CREATE INDEX idx_payments_invoice_id ON payments (invoice_id);
CREATE INDEX idx_payments_paid_at    ON payments (paid_at);

-- staff_attendance
CREATE INDEX idx_staff_attendance_staff_date ON staff_attendance (staff_id, date);
CREATE INDEX idx_staff_attendance_date       ON staff_attendance (date);

-- rooms
CREATE INDEX idx_rooms_status    ON rooms (status);
CREATE INDEX idx_rooms_room_type ON rooms (room_type);

-- guests
CREATE INDEX idx_guests_phone ON guests (phone);
CREATE INDEX idx_guests_email ON guests (email);

-- users
CREATE INDEX idx_users_role ON users (role);


-- =============================================================================
-- FUNCTION: auto-update updated_at columns
-- =============================================================================

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Attach to every table that carries updated_at
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_staff_updated_at
    BEFORE UPDATE ON staff
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_rooms_updated_at
    BEFORE UPDATE ON rooms
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_guests_updated_at
    BEFORE UPDATE ON guests
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_checkins_updated_at
    BEFORE UPDATE ON checkins
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_invoices_updated_at
    BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();


-- =============================================================================
-- FUNCTION + TRIGGER: sync rooms.status when checkin status changes
-- =============================================================================
--
--  Rules:
--    checkin INSERT  with status = 'active'       → room becomes 'occupied'
--    checkin UPDATE  status → 'active'             → room becomes 'occupied'
--    checkin UPDATE  status → 'checked_out'        → room becomes 'cleaning'
--    checkin UPDATE  status → 'cancelled'          → room becomes 'available'
--                                                    (only if no other active checkin)
-- =============================================================================

CREATE OR REPLACE FUNCTION fn_sync_room_status_on_checkin()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_active_count INTEGER;
BEGIN
    -- Determine the relevant room_id and new status
    IF TG_OP = 'INSERT' THEN
        IF NEW.status = 'active' THEN
            UPDATE rooms SET status = 'occupied' WHERE id = NEW.room_id;
        END IF;

    ELSIF TG_OP = 'UPDATE' THEN
        -- Only act when checkin status actually changes
        IF OLD.status IS DISTINCT FROM NEW.status THEN

            CASE NEW.status
                WHEN 'active' THEN
                    UPDATE rooms SET status = 'occupied' WHERE id = NEW.room_id;

                WHEN 'checked_out' THEN
                    -- Mark room as needing cleaning after checkout
                    UPDATE rooms SET status = 'cleaning' WHERE id = NEW.room_id;

                WHEN 'cancelled' THEN
                    -- Only free the room if no other active checkin exists for it
                    SELECT COUNT(*) INTO v_active_count
                    FROM   checkins
                    WHERE  room_id = NEW.room_id
                      AND  status  = 'active'
                      AND  id     <> NEW.id;

                    IF v_active_count = 0 THEN
                        UPDATE rooms SET status = 'available' WHERE id = NEW.room_id;
                    END IF;

                ELSE
                    -- No-op for any future statuses
                    NULL;
            END CASE;

        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_checkin_sync_room_status
    AFTER INSERT OR UPDATE OF status ON checkins
    FOR EACH ROW EXECUTE FUNCTION fn_sync_room_status_on_checkin();


-- =============================================================================
-- FUNCTION: generate invoice number  →  'INV-YYYY-NNNN'
-- =============================================================================
--
--  Usage:  SELECT fn_generate_invoice_number();   -- 'INV-2024-0001'
--
--  The sequence is global (not per-year). If you want a yearly reset,
--  replace the sequence with a per-year counter table instead.
-- =============================================================================

CREATE OR REPLACE FUNCTION fn_generate_invoice_number()
RETURNS VARCHAR(20)
LANGUAGE plpgsql
AS $$
DECLARE
    v_year   TEXT;
    v_seq    BIGINT;
    v_number VARCHAR(20);
BEGIN
    v_year   := TO_CHAR(NOW(), 'YYYY');
    v_seq    := NEXTVAL('invoice_number_seq');
    v_number := 'INV-' || v_year || '-' || LPAD(v_seq::TEXT, 4, '0');
    RETURN v_number;
END;
$$;

COMMENT ON FUNCTION fn_generate_invoice_number IS
    'Returns next invoice number in the format INV-YYYY-NNNN using invoice_number_seq';


-- =============================================================================
-- TRIGGER: auto-assign invoice number on INSERT if not provided
-- =============================================================================

CREATE OR REPLACE FUNCTION fn_assign_invoice_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.invoice_number IS NULL OR TRIM(NEW.invoice_number) = '' THEN
        NEW.invoice_number := fn_generate_invoice_number();
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_invoices_auto_number
    BEFORE INSERT ON invoices
    FOR EACH ROW EXECUTE FUNCTION fn_assign_invoice_number();


-- =============================================================================
-- FUNCTION + TRIGGER: recalculate invoice totals on INSERT / UPDATE
-- =============================================================================
--
--  Keeps subtotal, cgst_amount, sgst_amount, total_amount always consistent
--  with the individual charge columns so application code never has to
--  compute them manually.
-- =============================================================================

CREATE OR REPLACE FUNCTION fn_recalculate_invoice_totals()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_subtotal    DECIMAL(12,2);
    v_cgst        DECIMAL(12,2);
    v_sgst        DECIMAL(12,2);
BEGIN
    v_subtotal := GREATEST(0, NEW.room_charges + NEW.extra_charges - NEW.discount);
    v_cgst     := ROUND(v_subtotal * NEW.cgst_rate / 100, 2);
    v_sgst     := ROUND(v_subtotal * NEW.sgst_rate / 100, 2);

    NEW.subtotal     := v_subtotal;
    NEW.cgst_amount  := v_cgst;
    NEW.sgst_amount  := v_sgst;
    NEW.total_amount := v_subtotal + v_cgst + v_sgst;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_invoices_recalculate_totals
    BEFORE INSERT OR UPDATE OF room_charges, extra_charges, discount, cgst_rate, sgst_rate
    ON invoices
    FOR EACH ROW EXECUTE FUNCTION fn_recalculate_invoice_totals();


-- =============================================================================
-- FUNCTION + TRIGGER: auto-update invoice payment_status after each payment
-- =============================================================================
--
--  After any payment INSERT:
--    sum(payments.amount) >= invoices.total_amount  → 'paid'
--    sum(payments.amount) >  0                      → 'partial'
--    sum(payments.amount) == 0                      → 'pending'
-- =============================================================================

CREATE OR REPLACE FUNCTION fn_update_invoice_payment_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_paid    DECIMAL(12,2);
    v_invoice_total DECIMAL(12,2);
    v_new_status    payment_status;
BEGIN
    SELECT COALESCE(SUM(amount), 0),
           inv.total_amount
    INTO   v_total_paid,
           v_invoice_total
    FROM   payments p
    JOIN   invoices inv ON inv.id = p.invoice_id
    WHERE  p.invoice_id = NEW.invoice_id
    GROUP  BY inv.total_amount;

    IF v_total_paid >= v_invoice_total THEN
        v_new_status := 'paid';
    ELSIF v_total_paid > 0 THEN
        v_new_status := 'partial';
    ELSE
        v_new_status := 'pending';
    END IF;

    UPDATE invoices
    SET    payment_status = v_new_status,
           updated_at     = NOW()
    WHERE  id = NEW.invoice_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_payments_update_invoice_status
    AFTER INSERT ON payments
    FOR EACH ROW EXECUTE FUNCTION fn_update_invoice_payment_status();


-- =============================================================================
-- END OF MIGRATION 001_init.sql
-- =============================================================================
