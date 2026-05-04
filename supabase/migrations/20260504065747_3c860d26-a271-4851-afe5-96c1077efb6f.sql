
ALTER TABLE public.delivery_agents ADD COLUMN serial_number text;
ALTER TABLE public.agent_daily_closings ADD COLUMN closed_by uuid;
ALTER TABLE public.agent_daily_closings ADD COLUMN closed_by_username text;
ALTER TABLE public.offices ADD COLUMN is_active boolean NOT NULL DEFAULT true;
ALTER TABLE public.orders ADD COLUMN modified_amount numeric DEFAULT 0;

CREATE OR REPLACE FUNCTION public.delete_old_activity_logs()
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  DELETE FROM public.activity_logs WHERE created_at < now() - interval '30 days';
$$;

-- Fix prior function search_path warnings
ALTER FUNCTION public.update_updated_at_column() SET search_path = public;
ALTER FUNCTION public.clear_agent_on_revert() SET search_path = public;
