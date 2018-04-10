import pydocumentdb;
import pydocumentdb.document_client as document_client
import random
import string 
import datetime


# Initialize city

start=['cormoranche sur saone', 'plagne', 'tossiat', 'pouillat', 'torcieu', 'replonges', 'corcelles', 'peron', 'relevant', 'chaveyriat', 'vaux en bugey', 'maillat', 'faramans', 'beon', 'saint bernard', 'rossillon', 'pont d ain', 'nantua', 'chavannes sur reyssouze'];
end=['flaxieu', 'hotonnes', 'saint sorlin en bugey', 'songieu', 'virieu le petit', 'saint denis en bugey', 'charnoz sur ain', 'chazey sur ain', 'marchamp', 'culoz', 'mantenay montlin', 'marboz', 'foissiat', 'treffort cuisiat', 'izieu', 'saint etienne du bois', 'hauteville lompnes', 'saint trivier sur moignans', 'peyriat']


# Initialize Cosmos DB connection string 

config = { 
    'ENDPOINT': 'https://terraformcomsos.documents.azure.com:443/',
    'MASTERKEY': 'YM7SdqfT6H4MJdGJTuLpVeVjvODkRbXi8op7bcbEjdlmdUTwePFE70mwsoS1JrSRK7WaxrlKV19COcVECa0pyQ==',
    'DOCUMENTDB_DATABASE': 'db',
    'DOCUMENTDB_COLLECTION': 'coll'};

# Initialize the Python DocumentDB client

client = document_client.DocumentClient(config['ENDPOINT'], {'masterKey': config['MASTERKEY']})

while True:
    try:
        # Initialize database and collection information
        db_id = 'db'
        db_query = "select * from r where r.id = '{0}'".format(db_id)
        db = list(client.QueryDatabases(db_query))[0]
        db_link = db['_self']

        coll_id = 'coll'
        coll_query = "select * from r where r.id = '{0}'".format(coll_id)
        coll = list(client.QueryCollections(db_link, coll_query))[0]
        coll_link = coll['_self']
        
        # Create some documents
        for i in range(10):
            d=client.CreateDocument(coll_link,{
                'id' : ''.join([random.choice(string.ascii_letters + string.digits) for n in range(10)]),
                'Gare Depart' : random.choice(start),
                'Gare Arrivee' : random.choice(end),
                'Voie' : random.randint(1,10),
                'Retard' : random.randint(0,60),
                'Heure/Date' : str(datetime.datetime.now())})
         
    except IndexError:
        # Create a database
        db = client.CreateDatabase({ 'id': config['DOCUMENTDB_DATABASE'] })

        # Create collection options
        options = {
            'offerEnableRUPerMinuteThroughput': True,
            'offerVersion': "V2",
            'offerThroughput': 400}

        # Create a collection
        collection = client.CreateCollection(db['_self'], { 'id': config['DOCUMENTDB_COLLECTION'] }, options)

        # Create some documents
        for i in range(10):
            d=client.CreateDocument(coll,{'id' : ''.join([random.choice(string.ascii_letters + string.digits) for n in range(10)]),
                                            'Gare Depart' : random.choice(start),
                                            'Gare Arrivee' : random.choice(end),
                                            'Voie' : random.randint(1,10),
                                            'Retard' : random.randint(0,60),
                        						'Heure/Date' : str(datetime.datetime.now())})