%% All performanceormances (light, moderate, high)
%% All uses (gaming, editing, coding)
%% All sizes (regular, small)

:- dynamic(known/2).
:- dynamic(pct/2).
:- consult(database). %% Include the database

%% Handlers de los parametros de entrada

use(Use) :-
  ask(use, Use).

performance(Perf) :-
  ask(performance, Perf).

budget(Budget) :-
  ask(budget, X),
  Budget is float(X).

size(Size, F) :-
  ask(size, Size),
  (   Size == 'small'
  ->  F = 'Micro ATX'
  ;   Size == 'regular'
  ->  F = 'ATX'
  ).

ask(A, V) :-
  known(A, V),
  !.
ask(A, _) :-
  known(A, _),
  !,
  fail.
ask(A, V) :-
  write('Write the'), tab(1), write(A), write(': '),
  prompt(_, ''),
  read(V),
  asserta(known(A, V)).

fits_budget(N, P, Pct) :-
  budget(Budget),
  N*P =< Pct*Budget.

%% RAM minima en funcion del uso y performance
minram(Gigs) :-
  use('editing'),
  performance('high'),
  Gigs = 64.
minram(Gigs) :-
  performance('high'),
  Gigs = 32.
minram(Gigs) :-
  performance('moderate'),
  Gigs = 16.
minram(Gigs) :-
  Gigs = 8.

%% Checkea todas las CPUs compatibles con la entrada del usuario
listcpu(CL) :-
  performance(Perf),
  divide_budget,
  pct(cpu, Pct),
  findall(Cpu, (cpu(Cpu, _, _, _, performance(Perf), price(Price)), fits_budget(1, Price, Pct)), CL),
  CL \= [],
  !.
listcpu(_) :-
  write('Could not find CPU with those requirements.'),
  fail.

needs_igpu :-
  performance('light'),
  use(Use),
  \+ member(Use, ['gaming', 'editing']).

divide_budget :-
  needs_igpu,
  asserta(pct(cpu, 0.35)),
  asserta(pct(board, 0.25)),
  asserta(pct(case, 0.1)),
  asserta(pct(ram, 0.1)),
  asserta(pct(cooler, 0.1)),
  asserta(pct(psu, 0.1)).
divide_budget :-
  asserta(pct(cpu, 0.2)),
  asserta(pct(gpu, 0.4)),
  asserta(pct(board, 0.125)),
  asserta(pct(case, 0.05)),
  asserta(pct(ram, 0.075)),
  asserta(pct(cooler, 0.05)),
  asserta(pct(psu, 0.1)).

compgpu(Gpu, Name, Cpu) :- 
  needs_igpu,
  cpu(Cpu, _, igpu(Gpu), _, _, _),
  Gpu \= nan,
  Name = Gpu.
compgpu(Gpu, Name, _) :-
  pct(gpu, Pct),
  gpu(Name, model(Gpu), _, _, price(Price)),
  fits_budget(1, Price, Pct).
compgpu(Gpu, Name, _) :-
  Gpu = nan,
  Name = nan.

compboard(Board, Cpu) :-
  pct(board, Pct),
  size(_, Form),
  cpu(Cpu, socket(Socket), _, _, _, _),
  board(Board, socket(Socket), form_factor(Form), _, _, price(Price)),
  fits_budget(1, Price, Pct).
compboard(Board, _) :-
  Board = nan.

compcase(Case, Board) :-
  pct(case, Pct),
  size(_, Form),
  case(Case, form_factor(Form), price(Price)),
  board(Board, _, form_factor(Form), _, _, _),
  fits_budget(1, Price, Pct).
compcase(Case, _) :-
  Case = nan.

compram(Ram, Amount, Board) :-
  use(_),
  pct(ram, Pct),
  minram(Gigs),
  ram(Ram, modules(Mods), memory_per_module(Mem), price(Price)),
  board(Board, _, _, max_ram(Max), memory_slots(Slots), _),
  Max >= Gigs,
  Aux = Slots // Mods, % Amount of packs of ram to buy
  Amount is integer(Aux),
  Total = Amount*Mods*Mem,
  Total >= Gigs,
  fits_budget(Amount, Price, Pct).
compram(Ram, Amount, Board) :-
  use(_),
  pct(ram, Pct),
  minram(Gigs),
  ram(Ram, modules(Mods), memory_per_module(Mem), price(Price)),
  board(Board, _, _, max_ram(Max), memory_slots(Slots), _),
  Max >= Gigs,
  Aux = Gigs // Mem, % Amount of packs of ram to buy
  Amount is integer(Aux),
  Amount > 0,
  Amount*Mods =< Slots,
  fits_budget(Amount, Price, Pct).
compram(Ram, Amount, _) :-
  Ram = nan,
  Amount = nan.

comppsu(Psu, Cpu, Gpu, Name) :-
  needs_igpu,
  pct(psu, Pct),
  cpu(Cpu, _, igpu(Gpu), tdp(Tdp), _, _),
  Gpu \= nan,
  Name = Gpu,
  psu(Psu, wattage(Watts), price(Price)),
  Watts >= 1.2*Tdp,
  fits_budget(1, Price, Pct).
comppsu(Psu, Cpu, Gpu, Name) :-
  pct(psu, Pct),
  cpu(Cpu, _, _, tdp(CTdp), _, _),
  gpu(Name, model(Gpu), tdp(GTdp), _, _),
  psu(Psu, wattage(Watts), price(Price)),
  Total = CTdp + GTdp,
  Watts >= 1.2*Total,
  fits_budget(1, Price, Pct).
comppsu(Psu, _, _, _) :-
  Psu = nan.

compcool(Cooler, Cpu) :-
  pct(cooler, Pct),
  cpu(Cpu, socket(Socket), _, _, performance(Perf), _),
  cooler(Cooler, socket(SocketList), performance(Perf), price(Price)),
  member(Socket, SocketList),
  fits_budget(1, Price, Pct).
compcool(Cooler, _) :-
  Cooler = nan.

print_build(Cpu, Name, Gpu, Board, Ram, Cooler, Psu, Case, Amount) :-
  \+ member(nan, [Cpu, Name, Gpu, Board, Ram, Cooler, Psu, Case, Amount]),
  format('+~`-t~80|+ ~n'),
  cpu(Cpu, _, _, _, _, price(P1)),
  format('| ~s~t~15|| ~s~t~65+|~n', ['CPU', Cpu]),
  format('|~`-t~80|| ~n'),
  (   Name == Gpu ->
      P2 = 0,
      format('| ~s~t~15|| ~s~t~65+|~n', ['iGPU', Gpu])
  ;   atomics_to_string([Name, Gpu], NGpu),
      gpu(Name, _, _, _, price(P2)),
      string(NGpu),
      format('| ~s~t~15|| ~s~t~65+|~n', ['GPU', NGpu])
  ),
  format('|~`-t~80|| ~n'),
  board(Board, _, _, _, _, price(P3)),
  format('| ~s~t~15|| ~s~t~65+|~n', ['Motherboard', Board]),
  format('|~`-t~80|| ~n'),
  ram(Ram, modules(Mod), memory_per_module(Mem), price(AuxP)),
  P4 is AuxP*Amount,
  format('| ~s~t~15|| (x~w) ~w30 (~wx~wGB)~t~65+|~n', ['RAM', Amount, Ram, Mod, Mem]),
  format('|~`-t~80|| ~n'),
  cooler(Cooler, _, _, price(P5)),
  format('| ~s~t~15|| ~s~t~65+|~n', ['Cooler', Cooler]),
  format('|~`-t~80|| ~n'),
  psu(Psu, wattage(Watts), price(P6)),
  format('| ~s~t~15|| ~w30 ~wW~t~65+|~n', ['PSU', Psu, Watts]),
  format('|~`-t~80|| ~n'),
  case(Case, _, price(P7)),
  format('| ~s~t~15|| ~s~t~65+|~n', ['Case', Case]),
  PTotal is P1 + P2 + P3 + P4 + P5 + P6 + P7,
  format('|~`-t~80|| ~n'),
  format('|~`-t~80|| ~n'),
  format('| ~s~t~15|| ~2f EUR ~t~65+|~n', ['Price', PTotal]),
  format('+~`-t~80|+ ~n'), nl.

iter_print_build([], [], [], [], [], [], [], [], []).
iter_print_build([C|Cs], [N|Ns], [G|Gs], [B|Bs], [R|Rs], [O|Os], [P|Ps], [E|Es], [A|As]) :-
  print_build(C, N, G, B, R, O, P, E, A),
  iter_print_build(Cs, Ns, Gs, Bs, Rs, Os, Ps, Es, As).
iter_print_build([_|Cs], [_|Ns], [_|Gs], [_|Bs], [_|Rs], [_|Os], [_|Ps], [_|Es], [_|As]) :-
  iter_print_build(Cs, Ns, Gs, Bs, Rs, Os, Ps, Es, As).

main :-
  format('PC Configurator by Group F (Modelos de Razonamiento, 2021/2022)~n'),
  format('- Possible PC performances: light, moderate or high.~n'),
  format('- Possible PC sizes: small or regular.~n'),
  format('- Relevant PC uses that will alter the configuration: gaming and editing.~n'), nl,
  listcpu(CL),
  maplist(compgpu, GL, NL, CL),
  maplist(compboard, BL, CL),
  maplist(compcase, EL, BL),
  maplist(compram, RL, AL, BL),
  maplist(comppsu, PL, CL, GL, NL),
  maplist(compcool, OL, CL),
  nl,
  iter_print_build(CL, NL, GL, BL, RL, OL, PL, EL, AL),
  halt.
main :-
  format('Could not find a feasible configuration.~n'),
  fail,
  halt.
