objectPath = require 'object-path'
response = require '../response'

module.exports = (req, res, next) ->
  route = req._route
  policy = route['user-profile-policy']

  if policy
    pass = (policy.rules or []).reduce (prev, curr) ->
      if prev == true
        true  # if any rule is true, allow
      else
        pathOperand = objectPath.get req._profile, curr.pathOperand
        switch curr.operator
          when 'equals'
            pathOperand == curr.valueOperand
          when 'equalsIgnoreCase'
            pathOperand?.toLowerCase? and pathOperand.toLowerCase() == curr.valueOperand
          when 'includes'
            pathOperand?.includes? and pathOperand.includes curr.valueOperand
          when 'inList'
            curr.valueOperand.includes? and curr.valueOperand.includes pathOperand
          else false
    , null

    if not pass
      if policy.redirect
        res.set 'Location', policy.redirect
        response.send res, 303
      else
        response.send res, 403, 'Forbidden: The request failed to match the policy for this route'
    else
      next()
  else
    next()
