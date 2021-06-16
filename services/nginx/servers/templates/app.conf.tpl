map $http_origin $allow_cors {
    # Nginx will not return a header if its value is an empty string
    default "";
    "~(^|^http:\/\/)(localhost$|localhost:[0-9]{1,4}$)" "$http_origin";
    "~^https://test-.-dev.example.com$" "$http_origin"; # https://test-7-dev.example.com
    "https://example.com" "$http_origin";
}

map $http_origin $cors_credentials {
    # Nginx will not return a header if its value is an empty string
    default "";
    "~(^|^http:\/\/)(localhost$|localhost:[0-9]{1,4}$)" "true";
    "~^https://test-.-dev.example.com$" "true";
    "https://example.com" "true";
}

map $http_user_agent $deny_bot {
    default 0;
    ~*(""|google|Googlebot|bing|msnbot|yahoo|mail|Wordpress|Joomla|Drupal|feed|rss|XML-RPC|iTunes|Googlebot-Image|Googlebot-Video|Xenu|ping|Simplepie) 1;
    ~*(AltaVista|Slurp|BlackWidow|Bot|ChinaClaw|Custo|DISCo|Download|Demon|eCatch|EirGrabber|EmailSiphon|EmailWolf|Surfbot|BatchFTP|Harvest|Collector|Copier) 1;
    ~*(Express|WebPictures|ExtractorPro|FlashGet|GetRight|GetWeb!|Grafula|Go!Zilla|Go-Ahead-Got-It|Whacker|Extractor|lftp|clsHTTP|Mirror|Explorer) 1;
    ~*(rafula|HMView|HTTrack|Stripper|Sucker|Indy|InterGET|Ninja|JetCar|Spider|larbin|LeechFTP|Downloader|tool|Navroad|NearSite|NetAnts|tAkeOut|WWWOFFLE|Navigator|SuperHTTP|MIDown) 1;
    ~*(GrabNet|Snagger|Vampire|NetZIP|Octopus|Offline|PageGrabber|Foto|pavuk|pcBrowser|Openfind|ReGet|SiteSnagger|SmartDownload|SuperBot|WebSpider|Vacuum|WWW-Collector-E|LinkWalker) 1;
    ~*(Teleport|VoidEYE|WebAuto|WebCopier|WebFetch|WebGo|WebLeacher|Reaper|WebSauger|Quester|WebStripper|WebZIP|Wget|Widow|Zeus|WebBandit|Jorgee|Webclipping) 1;
    ~*(Twengabot|libwww|Python|perl|urllib|scan|Curl|email|PycURL|Pyth|PyQ|WebCollector|WebCopy|webcraw|WinHttp|okhttp|Java|Webster|Enhancer|trivial|LWP|Magnet) 1;
    ~*(Mag-Net|moget|Recorder|RepoMonkey|Siphon|AppsViewer|Lynx|Acunetix|FHscan|Baidu|Yandex|EasyDL|WebEMailExtrac|MJ12|FastProbe|spbot|DotBot|SemRush|Daum|DuckDuckGo) 1;
    ~*(Aboundex|teoma|80legs|360Spider|Alexibot|attach|BackWeb|Bandit|Bigfoot|Black.Hole|CopyRightCheck|BlowFish|Buddy|Bullseye|BunnySlippers|Cegbfeieh|CherryPicker|DIIbot) 1;
    ~*(Spyder|Crescent|AIBOT|dragonfly|Drip|ebingbong|Crawler|EyeNetIE|Foobot|flunky|FrontPage|hloader|Jyxobot|humanlinks|IlseBot|JustView|Robot|InfoTekies|Intelliseek|Jakarta) 1;
    ~*(Keyword|Iria|MarkWatch|likse|JOC|Mata.Hari|Memo|Microsoft.URL|Control|MIIxpc|Missigua|Locator|PIX|NAMEPROTECT|NextGenSearchBot|NetMechanic|NICErsPRO|Netcraft|niki-bot|NPbot|tracker) 1;
    ~*(Pockey|ProWebWalker|psbot|Pump|QueryN.Metasearch|SlySearch|Snake|Snapbot|Snoopy|sogou|SpaceBison|spanner|worm|suzuran|Szukacz|Telesoft|Intraformant|TheNomad|Titan|turingos) 1;
    ~*(URLy|Warning|VCI|WISENutbot|Xaldon|ZmEu|Zyborg|Aport|Parser|ahref|zoom|Powermarks|SafeDNS|BLEXBot|aria2|wikido|grapeshot|linkdexbot|Twitterbot|Google-HTTP-Java-Client) 1;
    ~*(Veoozbot|ScoutJet|DomainAppender|Go-http-client|SEOkicks|WHR|sqlmap|ltx71|InfoPath|Alltop|heritrix|indiensolidaritet|Experibot|magpie|RSSInclude|wp-android|Synapse) 1;
    ~*(GimmeUSAbot|istellabot|interfax|vebidoobot|Jetty|dataaccessd|Dalvik|eCairn|BazQux|Wotbox|null|scrapy-redis|weborama-fetcher|TrapitAgent|UNKNOWN|SeznamBot|BUbiNG) 1;
    ~*(cliqzbot|Deepnet|Ziba|linqia|portscout|Dataprovider|ia_archiver|MEGAsync|GroupHigh|Moreover|YisouSpider|CacheSystem|Clickagy|SMUrlExpander|XoviBot|MSIECrawler|Qwantify|JCE|tools.ua.random) 1;
    ~*(YaK|Mechanize|zgrab|Owler|Barkrowler|extlinks|achive-it|BDCbot|Siteimprove|Freshbot|WebDAV|Thumbtack|Exabot|mutant|Ukraine|NEWT|LinkextractorPro|LinkScan|LNSpiderguy) 1;
    ~*(Apache-HttpClient|Sphere|MegaIndex.ru|WeCrawlForThePeace|proximic|accelobot|searchmetrics|purebot|Ezooms|DinoPing|discoverybot|integromedb|visaduhoc|Searchbot|SISTRIX|brandwatch) 1;
    ~*(PeoplePal|PagesInventory|Nutch|HTTP_Request|Zend_Http_Client|Riddler|Netseer|CLIPish|Add\ Catalog|Butterfly|SocialSearcher|xpymep.exe|POGS|WebInDetail|WEBSITEtheWEB|CatchBot|rarely\ used) 1;
    ~*(ltbot|Wotbot|netEstate|news\ bot|omgilibot|Owlin|Mozilla--no-parent|Feed\ Parser|Feedly|Fetchbot|PHPCrawl|PhantomJS|SV1|R6_FeedFetcher|pilipinas|Proxy|PHP/5\.|DataCha0s|mobmail\ android) 1;
    #
    ~*(ahrefsbot|appengine|aqua_products|archive.org_bot|archive|asterias|attackbot|b2w|backdoorbot|becomebot|blekkobot|botalot|builtbottough|ccbot|cheesebot|chroot|clshttp|copernic) 1;
    ~*(dittospyder|dumbot|emailcollector|enterprise_search|erocrawler|eventmachine|extractorpro|stanford|surveybot|tocrawl|true_robot|copyscape|cosmos|craftbot|demon) 1;
    ~*(github|grub|hari|hatena|antenna|hloader|fairad|flaming|gaisbot|getty|gigabot|htmlparser|httplib|infonavirobot|intraformant|iron33|jamesbot|jennybot|jetbot|kenjin|leechftp) 1;
    ~*(lexibot|library|libweb|linkpadbot|linkwalker|lnspiderguy|looksmart|lwp-trivial|mass|mata|midown|mister|mj12bot|naver|nerdybot|netspider|ninja|openbot|openlink|papa|perl|perman|picscout) 1;
    ~*(python-urllib|queryn|radiation|realdownload|retriever|rma|rogerbot|screaming|frog|seo|webmasterworld|webmasterworldforumbot|webreaper|webvac|webviewer|webwhacker|wesee|woobot|xenu) 1;
    ~*(scooter|searchengineworld|searchpreview|semrushbot|semrushbot-sa|seokicks-robot|sootle|typhoeus|url_spider_pro|urldispatcher|warning|webenhancer|webleacher|propowerbot|python|spankbot) 1;
}

server {
    set $phpfpm_server ${APP_PHPFPM_DOCKER_SERVICE}:9000;
    set $host_path $APP_PATH_SRC/public;

    # Certification location
    include snippets/ssl-certificates.conf;

    # Strong TLS + TLS Best Practices
    include snippets/ssl.conf;

    # Redirect www to non-www
    include snippets/www-to-non-www.conf;

    # # NOTE: To use the HTTP challenge port 80 on NGINX must be open
    # listen 80;
    # include servers/shared/letsencrypt.conf;

    # server listen (HTTPS)
    listen 443 ssl http2;

    http2_push_preload on;
    http2_max_concurrent_pushes 25;

    server_name .yourdomain.tld;

    # server_name ~^(?<subdomain>.+)\.yourdomain\.tld$
    # server_name ~^(?<subdomain>.+)\.?(?<domain>yourdomain\.tld)$;
    # server_name ~^((?<subdomain>.+)\.)(?<domain>[^.]+)\.(?<tld>[^.]+)$;

    root $host_path;

    add_header Access-Control-Allow-Origin $allow_cors always;
    add_header Access-Control-Allow-Credentials $cors_credentials;
    add_header "Access-Control-Allow-Methods" "GET, POST, OPTIONS, HEAD";
    add_header "Access-Control-Allow-Headers" "Accept, Authorization, Cache-Control, Content-Type, DNT, If-Modified-Since, Keep-Alive, Origin, User-Agent, X-Requested-With";
    # # Required to be able to read Authorization header in frontend
    # add_header 'Access-Control-Expose-Headers' 'Authorization' always;

    # # Security HTTP Headers - It is not necessary because openresty/headers-more-nginx-module
    # include nginx.d/10-security-headers.conf;

    # Return 204 there is because this is configuration for load-balancer, and I don't want to send OPTIONS into certain host after load-balancer
    # NOTE: If you haven't load-balancer than you can remove this line
    if ($request_method = 'OPTIONS') {
        return 204 no-content;
    }

    if ($deny_bot = 1) {
        return 403;
    }

    # add_header X-City $geoip2_data_city_name;
    # add_header X-Country $geoip2_data_country_name;

    location / {
        try_files $uri $uri/ /index.php$is_args$query_string;

        limit_except GET {
            deny all;
        }

        #### Simple DDoS Defense / LIMITS
        #### Control Simultaneous Connections
        limit_conn conn_limit_per_ip 10;
        limit_req zone=req_limit_per_ip burst=10 nodelay;

        # Sets the status code to return in response to rejected requests
        limit_conn_status 460;
        limit_req_status 429;
    }

    location ~ /js/laroute.js {
        # kill cache
        add_header Last-Modified $date_gmt;
        add_header Cache-Control 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0';
        if_modified_since off;
        expires off;
        etag off;
    }

    location ~* (service-worker\.js)$ {
        add_header Cache-Control 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0';
        expires off;

        # @see https://developers.google.com/web/ilt/pwa/introduction-to-service-worker#registration_and_scope
        add_header 'Service-Worker-Allowed' '/';
    }

    # Prevent Hotlink
    location ~* \.(gif|png|jpe?g|ico|svg)$ {
        log_not_found off;
        access_log off;

        valid_referers none blocked ~.google. ~.bing. ~.yahoo. server_names ~($host) *.yourdomain.tld;

        if ($invalid_referer) {
            return 403 "Invalid Referer";
        }
    }

    # Alias assets images
    location ~ ^/assets/(/.*.(png|jpe?g))$ {
        alias $host_path/assets/images;

        autoindex off;
        access_log off;
    }

    # Several logs can be specified on the same level
    error_log /var/log/nginx/app.error.log warn;
    error_log /var/log/nginx/error.stderr.log warn;

    # # Sets the path, format, and configuration for a buffered log write
    # access_log /var/log/nginx/access.stdout.log main_json;
    access_log /var/log/nginx/app.main.access.log main_json;
    # access_log /var/log/nginx/app.performance.access.log performance;

    include snippets/deny.conf;
    include snippets/php-fpm.conf;
    include snippets/cache-static.conf;
}
