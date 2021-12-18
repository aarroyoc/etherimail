:- use_module(library(assoc)).
:- use_module(library(dcgs)).
:- use_module(library(lists)).
:- use_module(library(sockets)).
:- use_module(library(charsio)).
:- use_module(library(freeze)).
:- use_module(library(format)).
:- use_module(library(iso_ext), [setup_call_cleanup/3]).

:- use_module('../postgresql/postgresql').
% SMTP SERVER
% implements https://datatracker.ietf.org/doc/html/rfc5321
% tester https://smtper.net/, Gmail, Outlook, Cartero UVa

% TODO:
% - better close Server
% - automated Python Test

main :-
    Addr = '0.0.0.0',
    Port = 25,
    once(socket_server_open(Addr:Port, Socket)),
    format("Listening at port ~d\n", [Port]),
    accept_loop(Socket).

accept_loop(Socket) :-
    catch((
        socket_server_accept(Socket, _Client, Stream, [type(binary)]),
            format(Stream, "220 etherimail.com ESMTP EtheriMail\r\n", []),
            empty_assoc(Session),
            smtp_loop(Stream, Session),
            !, % remove
            close(Stream)
        ),
        _,
        true
    ),
    accept_loop(Socket).

smtp_loop(Stream, Session0) :-
    read_line(Stream, Bs),
    chars_utf8bytes(Cs, Bs),
    chars_lower(Cs, Cs1),
    phrase(smtp_(Command), Cs1),
    portray_clause(Command),
    smtp(Stream, Command, Session0, Session),
    smtp_loop(Stream, Session).

smtp_(helo(Server)) -->
    "helo ",
    string_(Server).

smtp_(ehlo(Server)) -->
    "ehlo ",
    string_(Server).

smtp_(mail_from(From)) -->
    "mail from:<",
    string_(From),
    ">",
    string_(_).

smtp_(rcpt_to(To)) -->
    "rcpt to:<",
    string_(To),
    ">",
    string_(_).

smtp_(data) -->
    "data".

smtp_(noop) -->
    "noop",
    string_(_).

smtp_(rset) -->
    "rset".

smtp_(quit) -->
    "quit".

smtp_(error) -->
    _.

smtp(Stream, helo(Server), Session0, Session) :-
    put_assoc(server, Session0, Server, Session),
    format(Stream, "250 Hello, this is etherimail.com\r\n", []).

smtp(Stream, ehlo(Server), Session0, Session) :-
    put_assoc(server, Session0, Server, Session),
    format(Stream, "250 Hello, this is etherimail.com\r\n", []).

smtp(Stream, mail_from(From), Session0, Session) :-
    put_assoc(from, Session0, From, Session),
    format(Stream, "250 Ok\r\n", []).

smtp(Stream, rcpt_to(To), Session0, Session) :-
    get_assoc(to, Session0, ToList),
    put_assoc(to, Session0, [To|ToList], Session),
    format(Stream, "250 Ok\r\n", []).

smtp(Stream, rcpt_to(To), Session0, Session) :-
    put_assoc(to, Session0, [To], Session),
    format(Stream, "250 Ok\r\n", []).

smtp(Stream, data, Session0, Session) :-
    format(Stream, "354 Enter message, ending with . on a line by itself\r\n", []),
    read_message(Stream, Message),
    join_message(Message, MessageFull),
    format(Stream, "250 Ok\r\n", []),
    put_assoc(msg, Session0, MessageFull, Session),
    save_msg(Session).

smtp(Stream, data, Session, Session) :-
    ( \+ get_assoc(from, Session, _)
    ; \+ get_assoc(to, Session, _)
    ),
    format(Stream, "503 Bad sequence of commands\r\n", []).

smtp(Stream, noop, Session, Session) :-
    format(Stream, "250 Ok\r\n", []).

smtp(Stream, rset, _, Session) :-
    empty_assoc(Session),
    format(Stream, "250 Ok\r\n", []).

smtp(Stream, quit, Session, Session) :-
    format(Stream, "221 Bye\r\n", []).

smtp(Stream, error, S, S) :-
    format(Stream, "500 Error\r\n", []).

read_line(Stream, Line) :-
    get_byte(Stream, Char),
    ( Char = -1 ->
        Line = []
    ; Char = 13 ->
        read_line(Stream, Line)
    ; Char = 10 ->
        Line = []
    ;   (read_line(Stream, Line0), Line = [Char|Line0])
    ).

read_message(Stream, [Cs|Message]) :-
    read_line(Stream, Bs),
    chars_utf8bytes(Cs, Bs),
    ( Cs = "." ->
        Message = []
    ;   read_message(Stream, Message)
    ).

% last line is not saved
% lines are joined with \n
join_message([_],[]).
join_message([X|Xs], Y) :-
    append(X, "\n", X1),
    join_message(Xs, Ys),
    append(X1, Ys, Y).

string_([X|Xs]) -->
    [X],
    string_(Xs).

string_([]) -->
    [].

save_msg(Session) :-
    get_assoc(from, Session, From),
    get_assoc(to, Session, To),
    get_assoc(msg, Session, Msg),
    connect("postgres", "postgres", postgres, 5432, "postgres", Connection),
    maplist(save_msg(Connection, From, Msg), To).

save_msg(Connection, From, Msg, To) :-
    phrase(format_("INSERT INTO mail (from_address, to_address, body) VALUES ('~s', '~s', '~s')", [From, To, Msg]), Query),
    query(Connection, Query, Status),
    ( Status = ok -> true
    ; portray_clause(Status)
    ).

% UTILS

chars_lower(Chars, Lower) :-
    maplist(char_lower, Chars, Lower).
char_lower(Char, Lower) :-
    char_code(Char, Code),
    ((Code >= 65,Code =< 90) ->
        LowerCode is Code + 32,
        char_code(Lower, LowerCode)
    ;   Char = Lower).

:- initialization(main).
