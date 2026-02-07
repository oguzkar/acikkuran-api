const { isNumeric } = require('../utils/funcs')
const authenticate = require('../middleware/authenticate')

async function routes(fastify) {
  // GET /user/translation?user_id=...&verse_id=...
  // Public read: any user can view translations by user_id + verse_id
  fastify.get('/user/translation', async (req, reply) => {
    const { user_id: userId, verse_id: verseId } = req.query

    if (!userId || !verseId || !isNumeric(+verseId)) {
      return reply.status(400).send({ error: 'invalid-params' })
    }

    try {
      const result = await fastify.pg.query(
        'SELECT id, user_id, verse_id, text, created_at, updated_at FROM acikkuran_user_translations WHERE user_id = $1 AND verse_id = $2 LIMIT 1',
        [userId, verseId]
      )

      const translation = result?.rows?.[0] || null
      
      // Fetch footnotes if translation exists
      if (translation) {
        const footnotesResult = await fastify.pg.query(
          'SELECT number, text FROM acikkuran_user_footnotes WHERE user_translation_id = $1 ORDER BY number',
          [translation.id]
        )
        translation.footnotes = footnotesResult?.rows || []
      }
      
      reply.send({ data: translation })
    } catch (error) {
      req.log.error({ err: error, userId, verseId }, 'user-translation-get-failed')
      reply.status(500).send({ error: 'user-translation-get-failed' })
    }
  })

  // POST /user/translation
  // Protected: requires a valid JWT. The user_id is extracted from the
  // token (req.user.id) so callers cannot impersonate other users.
  fastify.post(
    '/user/translation',
    { preHandler: [authenticate] },
    async (req, reply) => {
      // user_id comes from the verified JWT – not from the request body
      const userId = req.user.id
      const { verse_id: verseId, text, footnotes } = req.body || {}

      if (!verseId || !isNumeric(+verseId) || !text) {
        return reply.status(400).send({ error: 'invalid-params' })
      }

      try {
        const result = await fastify.pg.query(
          'INSERT INTO acikkuran_user_translations (user_id, verse_id, text) VALUES ($1, $2, $3) ' +
            'ON CONFLICT (user_id, verse_id) DO UPDATE SET text = EXCLUDED.text, updated_at = NOW() ' +
            'RETURNING id, user_id, verse_id, text, created_at, updated_at',
          [userId, verseId, text]
        )

        const translation = result?.rows?.[0]
        
        // Handle footnotes
        if (translation && footnotes && Array.isArray(footnotes)) {
          // Delete existing footnotes
          await fastify.pg.query(
            'DELETE FROM acikkuran_user_footnotes WHERE user_translation_id = $1',
            [translation.id]
          )
          
          // Insert new footnotes
          for (const footnote of footnotes) {
            if (footnote.text && footnote.number) {
              await fastify.pg.query(
                'INSERT INTO acikkuran_user_footnotes (user_translation_id, verse_id, user_id, number, text) VALUES ($1, $2, $3, $4, $5)',
                [translation.id, verseId, userId, footnote.number, footnote.text]
              )
            }
          }
          
          // Fetch saved footnotes
          const footnotesResult = await fastify.pg.query(
            'SELECT number, text FROM acikkuran_user_footnotes WHERE user_translation_id = $1 ORDER BY number',
            [translation.id]
          )
          translation.footnotes = footnotesResult?.rows || []
        } else {
          translation.footnotes = []
        }

        reply.send({ data: translation })
      } catch (error) {
        req.log.error({ err: error, userId, verseId }, 'user-translation-upsert-failed')
        reply.status(500).send({ error: 'user-translation-upsert-failed' })
      }
    }
  )
}

module.exports = routes
