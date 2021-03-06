###
PDFObject - converts JavaScript types into their corrisponding PDF types.
By Devon Govett
###

class PDFObject
  pad = (str, length) ->
    (Array(length + 1).join('0') + str).slice(-length)

  # Convert little endian UTF-16 to big endian
  swapBytes = (buff) ->
    l = buff.length
    if l & 0x01
      throw new Error("Buffer length must be even")
    else
      for i in [0...l - 1] by 2
        a = buff[i]
        buff[i] = buff[i + 1]
        buff[i+1] = a

    return buff

  @convert: (object) ->
    # String literals are converted to the PDF name type
    if typeof object is 'string'
      '/' + PDFEscape.escapeName(object)

    # String objects are converted to PDF strings (UTF-16)
    else if object instanceof String
      string = PDFEscape.escapeString(object)

      # Detect if this is a unicode string
      isUnicode = false
      for i in [0...string.length] by 1
        if string.charCodeAt(i) > 0x7f
          isUnicode = true
          break

      # If so, encode it as big endian UTF-16
      if isUnicode
        string = swapBytes(new Buffer('\ufeff' + string, 'utf16le')).toString('binary')

      '(' + string + ')'

    # Buffers are converted to PDF hex strings
    else if Buffer.isBuffer(object)
      '<' + object.toString('hex') + '>'

    else if object instanceof PDFReference ||
            object instanceof PDFNamedReference
      object.toString()

    else if object instanceof Date
      '(D:' + pad(object.getUTCFullYear(), 4) +
              pad(object.getUTCMonth() + 1, 2) +
              pad(object.getUTCDate(), 2) +
              pad(object.getUTCHours(), 2) +
              pad(object.getUTCMinutes(), 2) +
              pad(object.getUTCSeconds(), 2) +
      'Z)'

    else if Array.isArray object
      items = (PDFObject.convert e for e in object).join(' ')
      '[' + items + ']'

    else if {}.toString.call(object) is '[object Object]'
      out = ['<<']
      for key, val of object
        out.push '/' + key + ' ' + PDFObject.convert(val)

      out.push '>>'
      out.join '\n'

    else
      '' + object

module.exports = PDFObject
PDFEscape = require './escape'
PDFReference = require './reference'
PDFNamedReference = require './named_reference'
