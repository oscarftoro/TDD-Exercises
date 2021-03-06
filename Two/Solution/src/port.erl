-module(port).
-include("port.hrl").
-export([open/3,
	 close/1,
	 handle/2
	]).
-spec(open(string(),integer(),atom() | string()) -> {ok,#port{}} |
						    {error,no_such_module}|
						    {error,compile_error} |
						    {error,no_handle_function_exported}).
open(_,Port,echo) ->
    {ok,Sock} = gen_tcp:listen(Port,[{active,false},{reuseaddr,true}]),
    {ok,#port{type = echo,
	      socket = Sock,
	      number = Port}};
open(FileDir,Port,ModuleName) ->
    {ok,Files} = file:list_dir(FileDir),
    ErlSource = ModuleName++".erl",
    case lists:member(ErlSource,Files) of
	false ->
	    {error,no_such_module};
	true ->
	    case compile:file(filename:join(FileDir,ErlSource),[report_warnings,
								report_errors,
								binary]) of
		error ->
		    {error,compile_error};
		{ok,Module,Binary} ->
		    try_load(ModuleName,Module,ErlSource,Binary,Port)
	    end
    end.

try_load(ModuleName,Module,ErlSource,Binary,Port) ->
    {module,Module} = code:load_binary(Module,ErlSource,Binary),
    case erlang:function_exported(Module,handle,1) of
	false ->
	    {error,no_handle_function_exported};
	true ->
	    {ok,Sock} = gen_tcp:listen(Port,[{reuseaddr,true},
					     {active,false}]),		    
	    {ok,#port{type = ModuleName,
		      socket = Sock,
		      number = Port}}
    end.
    

-spec(close(#port{}) -> ok).
close(Port) ->
    gen_tcp:close(Port#port.socket).
	

-spec(handle(#port{},string()) -> string()).
handle(#port{type = echo},Input) ->
    Input;
handle(Port,Input) ->
    Mod = list_to_atom(Port#port.type),
    Mod:handle(Input).
    
    
