export type CommandResult = Record<string,unknown>;
export interface Repository { command(op:string,args:Record<string,unknown>):Promise<CommandResult> }
export async function supabaseRepository(url:string,key:string,environment:'production'|'preview'):Promise<Repository> {
  const {createClient}=await import('@supabase/supabase-js');
  const client=createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false,detectSessionInUrl:false}});
  const rpc=environment==='production'?'fault_waitlist_command':'fault_waitlist_preview_command';
  return {async command(op,args) { const {data,error}=await client.rpc(rpc,{p_op:op,p_args:args});if(error)throw new Error('database_unavailable');return data as CommandResult; }};
}
