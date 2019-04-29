module tracking.market;

import tracking.item;
import std.uri: encode;
import std.net.curl;
import std.stdio: writeln;
import std.file: read;
import std.string: split;
import std.json;
import std.conv: to, text;
import web.db;
import vibe.data.bson;
import vibe.db.mongo.mongo;
import std.datetime: dur, Clock;
import vibe.d: runTask, sleep;

// "http://steamcommunity.com/market/priceoverview/?appid=730&currency=3&market_hash_name=StatTrak%E2%84%A2 M4A1-S | Hyper Beast (Minimal Wear)"
immutable string queryURI = `https://steamcommunity.com/market/priceoverview/?appid=730&currency=1&market_hash_name=`;

private
{
    string[string] monthToNumber;
}

string createQueryURI(Item item)
{
    string uri = queryURI;
    if (item.stattrak)
        uri ~= stattrakQSTR;
    uri ~= item.name;
    uri ~= " (" ~ item.condition ~ ")";
    return uri;
}

struct QueryResult
{
    bool success = false;
    double lowest_price = 0;
    int volume = 0;
    double median_price = 0;
    string date = "";
}

string betterText(ubyte u)
{
    string s = u.text;
    if (s.length == 1)
        s ~= "0";
    return s;
}

QueryResult queryItem(Item item)
{
    string uri = item.createQueryURI.encode;
    uri.writeln;
    string content;
    try {
        content = cast(string)get(uri);
    } catch(Exception ex)
    {
        writeln(ex.msg);
        return QueryResult.init;
    }
    JSONValue json = parseJSON(content);
    QueryResult result;
    auto now = Clock.currTime;
    result.date = now.hour.text ~ ":" ~ now.minute.betterText ~ " " ~ monthToNumber[now.month.text] ~ "/" ~ now.day.text ~ "/" ~ now.year.text[2..$];
    if ("success" in json)
        result.success = json["success"].boolean;
    if ("lowest_price" in json)
        result.lowest_price = json["lowest_price"].str[1..$].to!double;
    if (result.lowest_price == double.nan)
        result.lowest_price = 0;
    if ("volume" in json)
        result.volume = json["volume"].str.to!int;
    if ("median_price" in json)
        result.median_price = json["median_price"].str[1..$].to!double;
    if (result.median_price == double.nan)
        result.median_price = 0;
    return result;
}

struct DBItem
{
    string name;
    Condition condition;
    bool stattrak;
    bool success;
    double lowest_price;
    int volume;
    double median_price;
}


string toURLName(DBItem item)
{
    string uri;
    if (item.stattrak)
        uri ~= stattrakQSTR;
    
    uri ~= item.name;
    uri ~= " (" ~ item.condition ~ ")";
    return uri.encode;
}


string toTableRow(DBItem item)
{
    import mood.templates: tr, td, th, a;
    import std.conv: text;
    return tr(
        th(a(item.name, `href="/item/` ~ item.toURLName ~ `"`))
        ~ td(item.stattrak ? "yes" : "no")
        ~ td(item.condition)
        ~ td(item.volume.text)
        ~ td('$' ~ item.lowest_price.text)
        ~ td('$' ~ item.median_price.text)
    );
}

string fullyQuallifiedName(DBItem i)
{
    string name;
    if (i.stattrak)
        name ~= stattrakQSTR;
    name ~= i.name;
    name ~= " ";
    name ~= "(" ~ cast(string)i.condition ~ ")";
    return name;
}



void saveQuery(Item item, QueryResult qr)
{
    if (qr == QueryResult.init || !qr.success)
        return;
    auto dbSaved = priceTracking.findOne(Bson([
        "name": Bson(item.name),
        "condition": Bson(item.condition),
        "stattrak": Bson(item.stattrak)
    ]));
    // not saved yet, insert
    if (dbSaved == Bson(null))
    {
        priceTracking.insert(Bson([
            "name": Bson(item.name),
            "condition": Bson(item.condition),
            "stattrak": Bson(item.stattrak),
            "history": Bson([ qr.serializeToBson ])
        ]));
    }
    else // update
    {
        priceTracking.update(Bson([
            "name": Bson(item.name),
            "condition": Bson(item.condition),
            "stattrak": Bson(item.stattrak)
        ]), Bson([
            "name": Bson(item.name),
            "condition": Bson(item.condition),
            "stattrak": Bson(item.stattrak),
            "history": Bson(cast(Bson[])dbSaved["history"] ~ qr.serializeToBson)
        ]));
        // writeln(cast(Bson[])dbSaved["history"]);
        // writeln(Bson([qr.serializeToBson]));
    }
    // static update in the items collection
    items.update(Bson(["name": Bson(item.name), "condition": Bson(item.condition), "stattrak": Bson(item.stattrak)]), 
        DBItem(item.name, item.condition, item.stattrak, qr.success, qr.lowest_price, qr.volume, qr.median_price), 
        UpdateFlags.upsert);
}

void scanSkins()
{
    // run our updating function :)
    while (true)
    {
        foreach(skin; (cast(string)read("skins.txt")).split("\n"))
        {
            if (skin.length == 0)
                continue;
            foreach(condition; ["Factory New", "Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred"])
            {
                for (int b = 0; b < 2; b++)
                {
                    Item i = Item(skin, cast(Condition)condition, cast(bool)b);
                    // i.writeln;
                    auto q = i.queryItem;
                    i.saveQuery(q);
                    sleep(dur!"msecs"(4000));
                }
            }
        }
    }
}

shared static this()
{
    monthToNumber = [
        "jan": "1",
        "feb": "2",
        "mar": "3",
        "apr": "4",
        "may": "5",
        "jun": "6",
        "jul": "7",
        "aug": "8",
        "sep": "9",
        "oct": "10",
        "nov": "11",
        "dec": "12",
    ];
    runTask(&scanSkins);
}
