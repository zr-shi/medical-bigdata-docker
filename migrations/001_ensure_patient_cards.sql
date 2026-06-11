-- Normalize legacy demo values and ensure every demo patient has a card.
-- This migration is idempotent and safe to run after every startup.
UPDATE medical_cards
SET card_type = _utf8mb4 0xE5AE9EE4BD93E58DA1
WHERE HEX(card_type) = 'C3A5C2AEC5BEC3A4C2BDE2809CC3A5C28DC2A1';

UPDATE medical_cards
SET card_type = _utf8mb4 0xE794B5E5AD90E58DA1
WHERE HEX(card_type) = 'C3A7E2809DC2B5C3A5C2ADC290C3A5C28DC2A1';

UPDATE medical_cards
SET status = _utf8mb4 0xE6ADA3E5B8B8
WHERE HEX(status) = 'C3A6C2ADC2A3C3A5C2B8C2B8';

INSERT INTO medical_cards (
    card_no,
    patient_id,
    patient_no,
    id_card,
    card_type,
    balance,
    status,
    issue_date,
    created_at,
    updated_at
)
SELECT
    CONCAT('DEMO-CARD-AUTO-', LPAD(p.id, 6, '0')),
    p.id,
    p.patient_no,
    p.id_card,
    _utf8mb4 0xE5AE9EE4BD93E58DA1,
    100.00,
    _utf8mb4 0xE6ADA3E5B8B8,
    COALESCE(p.created_at, NOW()),
    NOW(),
    NOW()
FROM patients p
WHERE NOT EXISTS (
    SELECT 1
    FROM medical_cards mc
    WHERE mc.patient_id = p.id
);
