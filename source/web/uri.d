module web.uri;

import std.string: indexOf;
import std.stdio: writeln;

string getParameter(string uri, string parameterName)
{
    uri = uri[1..$]; // strip leading "/"
    long idx = uri.indexOf('?');
    while (idx != -1)
    {
        long next = uri.indexOf('=', idx);
        string parameter = uri[idx+1..next];
        idx = uri.indexOf('&', next);
        if (idx == -1)
            idx = uri.length;
        string value = uri[next+1..idx];
        if (parameter == parameterName)
            return value;
        idx = uri.indexOf('&', idx+1);
    }
    return ""; // no parameter
}
