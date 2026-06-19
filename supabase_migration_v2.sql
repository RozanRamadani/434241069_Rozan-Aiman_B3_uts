ALTER TABLE tickets
ADD COLUMN IF NOT EXISTS accepted_at timestamptz NULL;

CREATE TABLE IF NOT EXISTS notifications (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id),
  ticket_id uuid REFERENCES tickets(id),
  title text NOT NULL,
  message text NOT NULL,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);