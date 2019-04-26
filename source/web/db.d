module web.db;

public import vibe.db.mongo.mongo;

MongoClient client;
MongoCollection users;
MongoCollection priceTracking;
MongoCollection items;

shared static this()
{
    client = connectMongoDB("127.0.0.1");
    users = client.getCollection("goose.users");
    priceTracking = client.getCollection("goose.tracking");
    items = client.getCollection("goose.items");
}

auto array(T)(MongoCursor!T cursor)
{
    T[] arr;
    foreach(d; cursor)
        arr ~= d;
    return arr;
}
