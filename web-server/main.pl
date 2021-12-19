:- use_module('../scryer-http-lyncex/http_server').
:- use_module('../teruel/teruel').
:- use_module('../postgresql/postgresql').

:- use_module(library(dcgs)).
:- use_module(library(format)).
:- use_module(library(lists)).
:- use_module(library(uuid)).

% TODO
% - Static middleware
% - Fix MIME content-type in http_body file sending
% - Add fecha caducidad visible in HTML
% - Really delete mails
% - Mails in HTML
% - Annex files

home(Request, Response) :-
    http_headers(Request, Headers),
    ( (member("cookie"-CookiesStr, Headers),
      string_cookies(CookiesStr, Cookies),
      member("etherimailId"-EtherimailId, Cookies)) ->
        true
    ;   (
            uuidv4_string(EtherimailId),
            phrase(format_("etherimailId=~s; Max-Age=86400", [EtherimailId]), SetCookieStr),
            http_headers(Response, ["set-cookie"-SetCookieStr])
        )
    ),
    phrase(format_("~s@mail.lyncex.com", [EtherimailId]), Email),
    html_render_response(Response, "index.html", ["email"-Email]).

string_cookies(Str, Cookies) :-
    once(phrase(cookies_(Cookies), Str)).

cookies_([Cookie|Cookies]) -->
    cookie_(Cookie),
    "; ",
    cookies_(Cookies).

cookies_([Cookie]) -->
    cookie_(Cookie).

cookies_([]) -->
    "".

cookie_(Name-Value) -->
    string_(Name),
    "=",
    string_(Value).

string_([X|Xs]) -->
    [X],
    string_(Xs).

string_([]) -->
    [].

mails(Request, Response) :-
    http_headers(Request, Headers),
    member("cookie"-CookiesStr, Headers),
    string_cookies(CookiesStr, Cookies),
    (
        member("etherimailId"-EtherimailId, Cookies) ->
        (
            phrase(format_("~s@mail.lyncex.com", [EtherimailId]), Email),
            connect("postgres", "postgres", postgres, 5432, "postgres", Connection),
            phrase(format_("SELECT from_address,body FROM mail WHERE to_address ='~s' ORDER BY date", [Email]), Query),
            query(Connection, Query, data(_, Rows)),
            maplist(row_mail, Rows, Mails),
            html_render_response(Response, "mails.html", ["mails"-Mails])
        )
    ;   http_status_code(Response, 400, "Not found")
    ).

row_mail(Row, Mail) :-
    Row = [From, Body],
    phrase((...,"Subject: ", seq(Subject),"\n",...), Body),
    phrase((...,"\n\n", seq(Content)), Body),
    Mail = ["from"-From, "subject"-Subject, "content"-Content].

main_css(_Request, Response) :-
    http_headers(Response, ["content-type"-"text/css"]),
    http_body(Response, file("main.css")).

htmx(_Request, Response) :-
    http_headers(Response, ["content-type"-"text/javascript"]),
    http_body(Response, file("htmx.min.js")).

main :-
    http_listen(7890, [
        get(/, home),
        get(mails, mails),
        get('main.css', main_css),
        get('htmx.min.js', htmx)
    ]).

:- initialization(main).