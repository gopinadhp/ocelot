config = require 'config'
originPortRegex = /(.*):\d+$/

domains = config.get('cors-domains')

endsWith = (str, suffix) ->
    str.indexOf(suffix, str.length - suffix.length) != -1

whitelistedDomain = (origin, url) ->
    if originPortRegex.test origin
        origin = originPortRegex.exec(origin)[1]
    domains? and origin? and (
      domains.filter((domain) -> endsWith(origin, ".#{domain}")).length > 0 or
      domains.indexOf(origin) > -1 or
      origin == 'null' and url.indexOf('receive-auth-token') > -1)

module.exports =
    shortCircuit: (req) ->
        {origin} = req.headers
        preflight = -> origin? and req.headers['access-control-request-method'] and req.method is 'OPTIONS'
        untrustredDomain = -> origin? and not whitelistedDomain origin, req.url

        preflight() or untrustredDomain()

    setCorsHeaders: (req, res) ->
        {origin} = req.headers
        headers = req.headers['access-control-request-headers']
        method = req.headers['access-control-request-method']

        if whitelistedDomain origin, req.url
            res.setHeader 'Access-Control-Allow-Origin', origin
            res.setHeader 'Access-Control-Max-Age', '1728000'
            res.setHeader 'Access-Control-Allow-Credentials', 'true'
        if headers then res.setHeader 'Access-Control-Allow-Headers', headers
        if method then res.setHeader 'Access-Control-Allow-Methods', method
