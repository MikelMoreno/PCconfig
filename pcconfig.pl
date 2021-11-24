%% All performances (light, medium, high)
%% All uses(gaming, editing, coding)
%% All OS (windows, macos, linux)

:- dynamic(known/2).

cpu('m1', ['light', 'medium'], ['linux', 'macos'], 'none', 'integrated').
cpu('ryzen 5 5800x', ['medium', 'high'], ['windows', 'linux'], 'am4', 'discrete').

gpu('m1', 'integrated', ['light']).
gpu('rtx 3060', 'discrete', ['medium', 'high']).

haveparams(Perf, Os) :-
  isknown(perf, Perf),
  isknown(os, Os).

isknown(A, V) :-
  not(known(A, V)),
  ask(A, V).
isknown(A, V) :-
  known(A, V).

use(Use) :-
  known(use, Use).
use(Use) :-
  ask(use, Use).

perf(Perf) :-
  known(perf, Perf).
perf(Perf) :-
  ask(perf, Perf).

os(Os) :-
  known(os, Os).
os(Os) :-
  ask(os, Os).

ask(A, V) :-
  write('Write the'), tab(1), write(A), write(': '),
  read(V),
  asserta(known(A, V)).

minram(R) :-
  use(editing),
  perf(high),
  R = 32.
minram(R) :-
  perf(high),
  R = 16.
minram(R) :-
  R = 8.

iscpu(CList) :-
  haveparams(Perf, Os),
  findall(C, (cpu(C, L1, L2, _, _), member(Perf, L1), member(Os, L2)), CList),
  CList \= [].
iscpu(_) :-
  write('No possible CPU with those requirements.'),
  fail.
  

