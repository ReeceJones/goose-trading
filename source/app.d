import vibe.d;
import mood.vibe;

import web.auth;
import tracking.market;

// https://stackoverflow.com/questions/26170185/steam-market-api

shared static this()
{
	auto router = new URLRouter;

	router.get("/", moodRender!"index.html");
	router.get("/login*", moodRender!"login.html");
	router.get("/create*", moodRender!"create.html");
	router.get("/lingo", moodRender!"lingo.html");
	router.get("/about", moodRender!"about.html");
	router.get("/logout", &handleLogout);
	router.get("/browse*", moodRender!"browse.html");
	router.get("/item/*", moodRender!"item.html");

	router.post("/create", &handleCreate);
	router.post("/login", &handleLogin);

	// always be at end
	router.get("*", serveStaticFiles("public/"));

	auto settings = new HTTPServerSettings;
	settings.port = 9001;
	settings.bindAddresses = ["::1", "0.0.0.0"];

	settings.sessionStore = new MemorySessionStore;

	listenHTTP(settings, router);
}
