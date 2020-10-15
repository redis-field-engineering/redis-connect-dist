def trackUpdates ( x ):
  stream = 'stream:emp:updates’
  key = x[ 'key' ][ 4 :] # Strip the prefix
  value = x[ 'value' ]
  keyTypes=['string', 'hash']
  eventTypes=['set', 'setex', 'setnx', 'hset', 'hsetnx', 'hmset', 'hincrby', 'hincrbyfloat']
  execute( 'XADD' , stream, '*' , 'key' , key, 'value' , value, 'type', keyTypes, 'event', eventTypes)

GearsBuilder( 'KeysReader' ) \
.foreach(trackUpdates) \
.register( mode = 'sync' , regex = 'emp:*', keyTypes = ['string', 'hash'],  eventTypes = ['set', 'setex', 'setnx', 'hset', 'hsetnx', 'hmset', 'hincrby', 'hincrbyfloat'])
