send = (res, statusCode, text) ->
    res.statusCode = statusCode
    if text
        res.write text
    res.end()

module.exports =
    send: send

    sendJSON: (res, statusCode, json) ->
        res.setHeader('Content-Type', 'application/json')
        send(res, statusCode, JSON.stringify(json))