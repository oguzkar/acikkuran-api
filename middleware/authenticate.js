const jwt = require('jsonwebtoken')

require('dotenv').config()

const JWT_SECRET = process.env.NEXTAUTH_SECRET

/**
 * Fastify preHandler hook that verifies the JWT token from the
 * Authorization header and attaches the authenticated user to the request.
 *
 * The JWT is signed by NextAuth.js on the frontend using HS256 with
 * the NEXTAUTH_SECRET. This middleware verifies the same token so that
 * we can trust the user identity without relying on user-supplied IDs.
 *
 * On success:  req.user = { id, email, name, ... }
 * On failure:  replies with 401
 */
async function authenticate(req, reply) {
  const authHeader = req.headers.authorization

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return reply.status(401).send({ error: 'missing-token' })
  }

  const token = authHeader.slice(7) // strip "Bearer "

  if (!JWT_SECRET) {
    req.log.error('NEXTAUTH_SECRET is not configured on the API server')
    return reply.status(500).send({ error: 'server-misconfigured' })
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET, { algorithms: ['HS256'] })

    // NextAuth stores the user id in `sub` (standard JWT subject claim)
    if (!decoded.sub) {
      return reply.status(401).send({ error: 'invalid-token' })
    }

    req.user = {
      id: decoded.sub,
      email: decoded.email,
      name: decoded.name,
    }
  } catch (err) {
    req.log.warn({ err }, 'jwt-verification-failed')
    return reply.status(401).send({ error: 'invalid-token' })
  }
}

module.exports = authenticate
