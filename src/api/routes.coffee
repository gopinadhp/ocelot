express = require 'express'
router = express.Router()
facade = require '../backend/facade'
response = require '../response'
log = require '../log'
config = require 'config'
crypto = require 'crypto'
context = require '../auth/context'

routeFields = ['capture-pattern', 'rewrite-pattern',
  'services', 'require-auth', 'client-whitelist',
  'user-header', 'client-header', 'user-id',
  'custom-headers', 'ent-app-id', 'user-profile-enabled',
  'elevated-trust', 'internal', 'hosts', 'user-profile-policy', 'audit-log', '_rev']

cookieFields = ['cookie-name', 'client-id',
  'client-secret', 'scope', 'cookie-path',
  'cookie-domain']

getRoute = (key) ->
  facade.getRoutes()
  .then (data) ->
    routes = data.filter (el) ->
      el.route == key
    if routes.length == 1
      routes[0]
    else
      throw new Error "route not found: #{key}"

shasum = (str) -> crypto.createHash('sha256').update(str).digest('hex')

router.get '/', (req, res) ->
  facade.getRoutes()
  .then (routes) ->
    routes.sort (a, b) -> a.route.localeCompare(b.route)
    for route in routes
      route['client-secret'] = shasum(route['client-secret']) if route['client-secret']
    res.json routes
  .catch (err) ->
    log.error "unable to load routes: #{err}"
    response.send res, 500, 'unable to load routes'

router.get /\/(.*)/, (req, res)->
  routeKey = req.params[0]
  getRoute(routeKey)
  .then (route) ->
    route['client-secret'] = shasum(route['client-secret']) if route['client-secret']
    res.json route
  , (err) ->
    response.send res, 404
  .catch (err) ->
    log.error "unable to get route #{route}, #{err}"
    response.send res, 500, 'unable to get route'

router.put /\/(.*)/, (req, res) ->
  routeKey = req.params[0]
  newObj = {}
  for own k,v of req.body
    if routeFields.indexOf(k) != -1 then newObj[k] = v
  if req.body[cookieFields[0]]
    for own k,v of req.body
      if cookieFields.indexOf(k) != -1 then newObj[k] = v

  newObj['user-id'] = context.getUserId(req) or 'unknown'

  Promise.resolve()
  .then ->
    if req.body['client-secret']
      getRoute(routeKey).then (route) ->
        if route['client-secret'] and newObj['client-secret'] == shasum(route['client-secret'])
          newObj['client-secret'] = route['client-secret']
      , () ->
  .then ->
    facade.putRoute(routeKey, JSON.stringify(newObj))
  .then ->
    response.send res, 200
  .catch (err) ->
    log.error "unable to save route #{route}, #{err}"
    response.send res, 500, 'unable to save route'

router.delete /\/(.*)/, (req, res) ->
  route = req.params[0]
  facade.deleteRoute(route)
  .then ->
    response.send res, 200
  .catch (err) ->
    log.error "unable to delete route #{route}, #{err}"
    response.send res, 500, 'unable to delete route'

module.exports = router
