db.restaurants.createIndex({"address.coord": "2d"})

db.restaurants.find(
	{
		"address.coord" : { 
			$near : [-74.0, 40.0]
		}
	},{
		name: 1, 
		"address.coord": 1, 
		borough:1, 
		cuisine:1
	}
).limit(10)

db.restaurants.aggregate([
	{
		$geoNear: {
			near: [-74.0, 40.0],
			key: "address.coord",
			distanceField: "calculated",
			distanceMultiplier: 6371
		}
	},
	{
		$sort: {"calculated": 1}
	},
	{
        	"$project": {
			"_id": "$_id", 
			"name" : "$name", 
			"cuisine":"$cuisine", 
			"address" : "$address", 
			"wholeGrade" : { $sum : { $sum : "$grades.score" }},
			"distance": "$calculated"
        	}
	},
	{ 
		$limit: 10 
	}
])
