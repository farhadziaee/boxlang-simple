## BoxLang simple web application

### Run
**Docker:**
```sh
docker compose up --build
```
**VSCode:** Alternatively, you can run the project directly in VSCode by using DevContainer. Once you've set up your DevContainer configuration, you can use the "Reopen in Container" command to open the project inside the container and run it directly from VSCode.

* URL: [http://localhost:8181](http://localhost:8181)

### Nginx
* Check this file `./nginx.conf`

### WebSocket
* Check this files
  * `./WebSocket.cfc`
  * `./public/script.js`

### MySql
* extension: `bx-mysql`
* Queries: `./classes/db.bx`

### Web Requests & Routing
* `./classes/core/WebRequest.bx`
* `./classes/core/WebRoute.bx`
* `./app/router.bx`

### i18n internationalization
* `./i18n/*.json`
* To reload translations open this link: `/?reinit=test`
* `test` is `BOXLANG_REINIT_PASSWORD`, an envirment variable

  
Made with ♥️ Farhad Ziaee 
