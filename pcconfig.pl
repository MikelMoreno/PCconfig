%% All performances (light, medium, high)
%% All uses(gaming, editing, coding)

:- dynamic(known/2).
:- consult(database). % Include the database

isknown(A, V) :-
  not(known(A, V)),
  ask(A, V).
isknown(A, V) :-
  known(A, V).

% Handlers de los parametros de entrada
use(Use) :-
  known(use, Use).
use(Use) :-
  ask(use, Use).

perf(Perf) :-
  known(perf, Perf).
perf(Perf) :-
  ask(perf, Perf).

budget(Budget) :-
  known(budget, Budget).
budget(Budget) :-
  ask(budget, Budget),
  Budget = float(Budget).

ask(A, V) :-
  write('Write the'), tab(1), write(A), write(': '),
  read(V),
  asserta(known(A, V)).

% RAM minima en funcion del uso y performance
minram(R) :-
  use(editing),
  perf('high'),
  R = 32.
minram(R) :-
  perf('high'),
  R = 16.
minram(R) :-
  R = 8.

% Checkea la compatibilidad de la GPU con la CPU
compgpu(G) :-
  cpu(_, _, _, _, gputype(X)),
  gpu(G, gputype(X)).

% Checkea todas las CPUs compatibles con la entrada del usuario
compcpu(CPUList) :-
  isknown(perf, Perf),
  isknown(budget, Budget),
  findall(C, (cpu(C, _, _, _, perf(Perf), price(P2)), P2 =< 0.2*Budget), CPUList),
  CPUList \= [].
compcpu(_) :-
  write('No possible CPU with those requirements.'),
  fail.
  

