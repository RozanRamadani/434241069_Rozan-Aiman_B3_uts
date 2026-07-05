create table public.tickets (
  id uuid not null default extensions.uuid_generate_v4 (),
  title text not null,
  description text not null,
  category text not null,
  status text null default 'Menunggu Antrean'::text,
  created_at timestamp with time zone not null default timezone ('utc'::text, now()),
  user_id uuid null,
  attachment_url text null,
  assigned_to uuid null,
  assigned_at timestamp with time zone null,
  processed_at timestamp with time zone null,
  resolved_at timestamp with time zone null,
  cancelled_at timestamp with time zone null,
  accepted_at timestamp with time zone null,
  constraint tickets_pkey primary key (id),
  constraint tickets_assigned_to_fkey foreign KEY (assigned_to) references profiles (id) on delete set null,
  constraint tickets_user_id_fkey foreign KEY (user_id) references profiles (id) on delete set null
) TABLESPACE pg_default;

create trigger tickets_status_audit
after
update OF status on tickets for EACH row
execute FUNCTION log_ticket_status_change ();

create table public.ticket_history (
  id uuid not null default gen_random_uuid (),
  ticket_id uuid null,
  user_id uuid null,
  old_status character varying(50) null,
  new_status character varying(50) null,
  changed_at timestamp with time zone null default now(),
  constraint ticket_history_pkey primary key (id),
  constraint ticket_history_ticket_id_fkey foreign KEY (ticket_id) references tickets (id) on delete CASCADE,
  constraint ticket_history_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete set null
) TABLESPACE pg_default;

create table public.ticket_comments (
  id uuid not null default extensions.uuid_generate_v4 (),
  ticket_id uuid null,
  user_id uuid null,
  message text not null,
  created_at timestamp with time zone not null default timezone ('utc'::text, now()),
  constraint ticket_comments_pkey primary key (id),
  constraint ticket_comments_ticket_id_fkey foreign KEY (ticket_id) references tickets (id) on delete CASCADE,
  constraint ticket_comments_user_id_fkey foreign KEY (user_id) references profiles (id) on delete CASCADE
) TABLESPACE pg_default;

create table public.profiles (
  id uuid not null,
  full_name text null,
  role text null default 'user'::text,
  updated_at timestamp with time zone null default now(),
  is_active boolean null default true,
  constraint profiles_pkey primary key (id),
  constraint profiles_id_fkey foreign KEY (id) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;

create table public.notifications (
  id uuid not null default gen_random_uuid (),
  user_id uuid null,
  ticket_id uuid null,
  title text not null,
  message text not null,
  is_read boolean null default false,
  created_at timestamp with time zone null default now(),
  constraint notifications_pkey primary key (id),
  constraint notifications_ticket_id_fkey foreign KEY (ticket_id) references tickets (id),
  constraint notifications_user_id_fkey foreign KEY (user_id) references auth.users (id)
) TABLESPACE pg_default;

create table public.categories (
  id uuid not null default gen_random_uuid (),
  name text not null,
  icon text not null,
  color text not null default '#FF6B35'::text,
  is_active boolean null default true,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint categories_pkey primary key (id)
) TABLESPACE pg_default;

create table public.activity_logs (
  id uuid not null default gen_random_uuid (),
  user_id uuid null,
  ticket_id uuid null,
  action text not null,
  description text null,
  created_at timestamp with time zone null default now(),
  constraint activity_logs_pkey primary key (id),
  constraint activity_logs_ticket_id_fkey foreign KEY (ticket_id) references tickets (id),
  constraint activity_logs_user_id_fkey foreign KEY (user_id) references auth.users (id)
) TABLESPACE pg_default;
