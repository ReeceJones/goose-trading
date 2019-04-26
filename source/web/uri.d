module web.uri;

import std.string: indexOf;
import std.stdio: writeln;

string getParameter(string uri, string parameterName)
{
    uri = uri[1..$]; // strip leading "/"
    long idx = uri.indexOf('&');
    while (idx != -1)
    {
        long startingPoint = uri.indexOf('&');
        startingPoint = startingPoint == -1 ? 0 : startingPoint + 1;
        long assignment = uri.indexOf('=', idx+1);
        string parameter = uri[startingPoint..assignment];
        // parameter.writeln;
        long nextParameter = uri.indexOf('&', assignment+1);
        nextParameter = nextParameter == -1 ? cast(long)uri.length : nextParameter;
        if (parameter == parameterName)
        {
            return uri[assignment+1..nextParameter];
        }
        uri = uri[nextParameter..$];
        idx = uri.indexOf('&');
    }
    return ""; // no parameter
}