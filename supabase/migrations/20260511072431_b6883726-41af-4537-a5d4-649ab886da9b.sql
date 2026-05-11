ALTER TABLE public.agent_dailies
  ADD CONSTRAINT agent_dailies_delivery_agent_id_fkey
  FOREIGN KEY (delivery_agent_id) REFERENCES public.delivery_agents(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_agent_dailies_agent ON public.agent_dailies(delivery_agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_dailies_date ON public.agent_dailies(daily_date);