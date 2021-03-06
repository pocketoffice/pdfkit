###
PDFReference - represents a reference to another object in the PDF object heirarchy
By Devon Govett
###

zlib = require 'zlib'
PDFNamedReference = require './named_reference'

class PDFReference
  constructor: (@document, @id, @data = {}, @options = {}) ->
    @gen = 0
    @deflate = null
    @compress = (@options.compress ? true) and @document.compress and not @data.Filter
    @uncompressedLength = 0
    @chunks = []

  initDeflate: ->
    @data.Filter = 'FlateDecode'

    @deflate = zlib.createDeflate()
    @deflate.on 'data', (chunk) =>
      @chunks.push chunk
      @data.Length += chunk.length

    @deflate.on 'end', @finalize

  write: (chunk) ->
    unless Buffer.isBuffer(chunk)
      chunk = new Buffer(chunk + '\n', 'binary')

    @uncompressedLength += chunk.length
    @data.Length ?= 0

    if @compress
      @initDeflate() if not @deflate
      @deflate.write chunk
    else
      @chunks.push chunk
      @data.Length += chunk.length

  end: (chunk) ->
    if typeof chunk is 'string' or Buffer.isBuffer(chunk)
      @write chunk

    if @deflate
      @deflate.end()
    else
      @finalize()

  finalize: =>
    @offset = @document._offset

    @document._write "#{@id} #{@gen} obj"
    @document._write PDFObject.convert(@data)

    if @chunks.length
      @document._write 'stream'
      for chunk in @chunks
        @document._write chunk

      @chunks.length = 0 # free up memory
      @document._write '\nendstream'

    @document._write 'endobj'
    @document._refEnd(this)

  toString: ->
    return "#{@id} #{@gen} R"

  namedReference: (name)->
    @_namedReference ||= new PDFNamedReference(this, name)

module.exports = PDFReference
PDFObject = require './object'
