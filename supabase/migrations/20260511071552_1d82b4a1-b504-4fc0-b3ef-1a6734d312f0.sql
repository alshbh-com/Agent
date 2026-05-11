CREATE TABLE public.agent_dailies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_agent_id uuid,
  daily_date date NOT NULL,
  daily_amount numeric NOT NULL DEFAULT 0,
  prepaid_amount numeric NOT NULL DEFAULT 0,
  total_collected numeric NOT NULL DEFAULT 0,
  total_returns numeric NOT NULL DEFAULT 0,
  remaining_amount numeric NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'open',
  notes text,
  closed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.agent_dailies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ad public" ON public.agent_dailies FOR ALL USING (true) WITH CHECK (true);

CREATE TRIGGER update_agent_dailies_updated_at
BEFORE UPDATE ON public.agent_dailies
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
