%% All performanceormances (light, moderate, high)
%% All uses(gaming, editing, coding)

:- dynamic(known/2).
:- consult(database). %% Include the database

%% Handlers de los parametros de entrada
use(Use) :-
  known(use, Use).
use(Use) :-
  ask(use, Use).

performance(Perf) :-
  not(known(performance, Perf)),
  ask(performance, Perf).
performance(Perf) :-
  known(performance, Perf).

budget(Budget) :-
  not(known(budget, X)),
  ask(budget, X),
  Budget is float(X).
budget(Budget) :-
  known(budget, X),
  Budget is float(X).

ask(A, V) :-
  write('Write the'), tab(1), write(A), write(': '),
  read(V),
  asserta(known(A, V)).

%% RAM minima en funcion del uso y performanceormance
minram(R) :-
  use(editing),
  performance('high'),
  R = 32.
minram(R) :-
  performance('high'),
  R = 16.
minram(R) :-
  R = 8.

%% Obtener lista de PSUs
listpsu([], [], [], []).
listpsu([C|Cs], [G|Gs], [N|Ns], [S|Ss]) :-
  performance('light'),
  budget(Budget),
  cpu(C, _, igpu(G1), tdp(T), _, _),
  G1 \= nan,
  G1 = G,
  N = G,
  psu(S, wattage(W), _, price(P)),
  W >= T,
  P =< 0.1*Budget,
  listpsu(Cs, Gs, Ns, Ss).
listpsu([C|Cs], [G|Gs], [N|Ns], [S|Ss]) :-
  budget(Budget),
  cpu(C, _, _, tdp(T1), _, _),
  gpu(N, model(G), tdp(T2), _, _),
  psu(S, wattage(W), _, price(P)),
  W >= T1 + T2,
  P =< 0.1*Budget,
  listpsu(Cs, Gs, Ns, Ss).

%% Checkea compatibilidad de la board con la CPU
listmb([], []).
listmb([C|Cs], [B|Bs]) :-
  budget(Budget),
  cpu(C, socket(S), _, _, _, _),
  board(B, socket(S), _, _, _, price(P)),
  P =< 0.15*Budget,
  listmb(Cs, Bs).

%% Checkea cooler compatibilidad con CPU
listcool([], []).
listcool([C|Cs], [U|Us]) :-
  budget(Budget),
  cpu(C, socket(S), _, _, performance(F), _),
  cooler(U, socket(SL), performance(F), price(P)),
  member(S, SL),
  P =< 0.05*Budget,
  listcool(Cs, Us).

%% Checkea la compatibilidad de la GPU con la CPU
listgpu([], [], []).
listgpu([C|Cs], [G|Gs], [N|Ns]) :-
  performance('light'),
  cpu(C, _, igpu(G), _, _, _),
  G \= nan,
  N = G,
  listgpu(Cs, Gs, Ns).
listgpu([_|Cs], [G|Gs], [N|Ns]) :-
  budget(Budget),
  gpu(N, model(G), _, _, price(P)),
  P =< 0.4*Budget,
  listgpu(Cs, Gs, Ns).

%% Checkea todas las CPUs compatibles con la entrada del usuario
listcpu(CL) :-
  performance(Perf),
  budget(Budget),
  findall(C, (cpu(C, _, _, _, performance(Perf), price(P)), P =< 0.2*Budget), CL),
  CL \= [].
listcpu(_) :-
  write('No possible CPU with those requirements.'),
  fail.

build :-
  listcpu(CL),
  listgpu(CL, GL, NL),
  listmb(CL, BL),
  listcool(CL, UL),
  listpsu(CL, GL, NL, SL),
  write(CL), nl,
  write(NL), nl,
  write(BL), nl,
  write(UL), nl,
  write(SL).

test(1) :-
  listcpu(CL),
  listgpu(CL, GL, NL),
  listpsu(CL, GL, NL, SL),
  write(CL), nl,
  write(GL), nl,
  write(SL).

