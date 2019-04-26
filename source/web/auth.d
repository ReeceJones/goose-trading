module web.auth;

import std.stdio: writeln;
import dauth;
import vibe.http.server: HTTPServerRequest, HTTPServerResponse;
import web.db;
import web.user;

void handleLogin(HTTPServerRequest req, HTTPServerResponse res)
{
    if (!("username" in req.form) || ("username" in req.form && req.form["username"] == ""))
    {
        res.redirect("/login&noname");
        return;
    }
    else if (!("password" in req.form) || ("password" in req.form && req.form["password"] == ""))
    {
        res.redirect("/login&nopass");
        return;
    }
    else
    {
        // check to see if the password/username are a match
        auto q = users.find!(User)(["username" : req.form["username"]]);
        if (isSameHash(toPassword(cast(char[])req.form["password"]), parseHash(q.front.password)))
        {
            auto session = res.startSession();
            session.set("username", q.front.username);
            session.set("superAdmin", q.front.superAdmin);
            res.redirect("/");
            return;
        }
        else
        {
            res.redirect("/");
            return;
        }
    }
}

void handleCreate(HTTPServerRequest req, HTTPServerResponse res)
{
    if (!("username" in req.form) || ("username" in req.form && req.form["username"] == ""))
    {
        res.redirect("/create&noname");
        return;
    }
    else if (!("password" in req.form) || ("password" in req.form && req.form["password"] == ""))
    {
        res.redirect("/create&nopass");
        return;
    }
    else
    {
        // check to see if the password/username are a match
        auto q = users.find!(User)(["username" : req.form["username"]]);
        if (!q.empty)
        {
            res.redirect("/create&exists");
            return;
        }
        else
        {
            User user;
            user.username = req.form["username"];
            user.password = makeHash(toPassword(cast(char[])req.form["password"])).toString();
            user.superAdmin = user.username == "reece";
            users.insert(user);

            auto session = res.startSession();
            session.set("username", user.username);
            session.set("superAdmin", user.superAdmin);
            res.redirect("/");

            return;
        }
    }
}

void handleLogout(HTTPServerRequest req, HTTPServerResponse res)
{
    res.terminateSession();
    res.redirect("/login");
}
