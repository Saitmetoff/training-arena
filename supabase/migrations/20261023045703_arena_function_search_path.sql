-- Pin resolution for Arena helpers flagged by the hosted security advisor.
-- No pre-existing Fault/fb helpers, grants or function bodies are changed.
alter function public.arena_touch_updated_at() set search_path = public, pg_temp;
alter function public.arena_forbid_mutation() set search_path = public, pg_temp;
alter function public.arena_new_token() set search_path = public, extensions, pg_temp;
alter function public.arena_fail(text,text) set search_path = public, pg_temp;
