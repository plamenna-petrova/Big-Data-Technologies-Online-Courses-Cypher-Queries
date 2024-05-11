
// Example queries for the Graph database

// 1) Get details of users enrolled for the course "Macroeconomics: A Comprehensive Economics Course"
MATCH (user:User)-[:ENROLLED_FOR_COURSE]->(:Course {name: "Macroeconomics: A Comprehensive Economics Course"})
RETURN user.firstName AS UserFirstName, user.lastName AS UserLastName, user.email AS UserEmail

// 2) Get uploaded materials for the course "ASP.NET Core - Cross-Platform Development" by its instructors
MATCH (instructor:Instructor)-[:UPLOADED_MATERIAL]->(material:Material)<-[:INCLUDES_MATERIAL]-(course:Course {name: "ASP.NET Core - Cross-Platform Development"})
RETURN material.title AS MaterialTitle, instructor.firstName + ' ' + instructor.lastName AS InstructorFullName 

// 3) Get the uploaded materials of the instructor Chris Haroun with their corresponding course and category
MATCH (instructor:Instructor {firstName: "Chris", lastName: "Haroun"})-[:UPLOADED_MATERIAL]->(material:Material)<-[:INCLUDES_MATERIAL]-(course:Course)-[belongsToCategory:BELONGS_TO_CATEGORY]->(category:Category)
RETURN course.name AS CourseName, material.title AS MaterialTitle, category.name AS CourseCategory
ORDER BY material.title ASC

// 4) Get top rated courses with their corresponding categories. Their rating is calculated on average of all evaluated materials, included in them
MATCH (course:Course)-[:INCLUDES_MATERIAL]->(material:Material)<-[evaluatedMaterial:EVALUATED_MATERIAL]-(user:User)
WITH course, AVG(evaluatedMaterial.rating) AS averageRating
ORDER BY averageRating DESC
LIMIT 7
MATCH (course)-[:BELONGS_TO_CATEGORY]->(category:Category)
RETURN course.name AS CourseName, category.name AS CourseCategory, averageRating AS CourseAverageRating

// 5) Get the full courses details, for which the user "Alex Johnson" has enrolled for with their instructors
MATCH (user:User {firstName: "Alex", lastName: "Johnson"})-[:ENROLLED_FOR_COURSE]->(course:Course)<-[:TEACHES_COURSE]-(instructor:Instructor)
WITH course, COLLECT(instructor.firstName + ' ' + instructor.lastName) AS instructorNames, COLLECT(instructor.email) AS instructorEmails
RETURN course.name AS CourseName, course.description AS CourseDescription, course.price AS CoursePrice, course.certificateOnCompletion AS CertificateOnCompletion,
       REDUCE(i = '', instructorName IN instructorNames | i + CASE WHEN i = '' THEN instructorName ELSE ', ' + instructorName END) AS Instructors,
       REDUCE(e = '', instructorEmail IN instructorEmails | e + CASE WHEN e = '' THEN instructorEmail ELSE ', ' + instructorEmail END) AS InstructorsEmails

// 6) Get the downloaded materials of the user sarah wilson, their ratings with comments and to which course they belong to
MATCH (user:User {firstName: "Sarah", lastName: "Wilson"})-[:DOWNLOADED_MATERIAL]->(material:Material)<-[evaluatedMaterial:EVALUATED_MATERIAL]-(user)
MATCH (material)<-[:INCLUDES_MATERIAL]-(course:Course)
RETURN material.title AS MaterialName, material.type AS MaterialType,
course.name AS CourseName, evaluatedMaterial.rating AS Rating, evaluatedMaterial.comment AS Comment

// 7) Get the lowest rated video lecturers, to which course they belong to and which instructor had uploaded them
MATCH (material:Material {type: "Video Lecture"})<-[evaluatedMaterial:EVALUATED_MATERIAL]-()
WITH material, evaluatedMaterial.rating AS Rating
ORDER BY Rating ASC
LIMIT 5
MATCH (material)<-[:INCLUDES_MATERIAL]-(course:Course)<-[:TEACHES_COURSE]-(instructor:Instructor)
RETURN material.title AS MaterialName, course.name AS CourseName, instructor.firstName + ' ' + instructor.lastName AS InstructorFullName, Rating

// 8) Get the count of courses of the category "Design"
MATCH (:Category {name: "Design"})<-[:BELONGS_TO_CATEGORY]-(course:Course)
RETURN COUNT(course) AS CourseCount

// 9) Get the courses names, which have more than one user enrolled for them and their categories
MATCH (course:Course)<-[:ENROLLED_FOR_COURSE]-(user:User)
WITH course, COUNT(DISTINCT user) AS enrolledUsersCount
WHERE enrolledUsersCount > 1
MATCH (course)-[:BELONGS_TO_CATEGORY]->(category:Category)
RETURN course.name AS CourseName, category.name AS CategoryName

// 10) Get the users names, who have enrolled for more than one course and which materials they have downloaded
MATCH (user:User)-[:ENROLLED_FOR_COURSE]->(course:Course)
WITH user, COUNT(course) AS enrolledCoursesCount
WHERE enrolledCoursesCount > 1
MATCH (user)-[:DOWNLOADED_MATERIAL]->(material:Material)
RETURN user.firstName AS FirstName, user.lastName AS LastName, 
       REDUCE(m = "", material IN COLLECT(material.title) | m + CASE WHEN m = "" THEN material ELSE ', ' + material END) AS DownloadedMaterials

// 11) Get the lowest and highest rated instructors and the courses they teach, calculate the rating on average by the evaluated materials by users
MATCH (course:Course)-[:INCLUDES_MATERIAL]->(material:Material)<-[evaluatedMaterial:EVALUATED_MATERIAL]-(user:User)
WITH course, AVG(evaluatedMaterial.rating) AS averageRating
ORDER BY averageRating DESC
LIMIT 1
MATCH (course)<-[:TEACHES_COURSE]-(instructor:Instructor)
RETURN course.name AS CourseName, instructor.firstName + ' ' + instructor.lastName AS InstructorFullName, averageRating AS CourseAverageRating
UNION
MATCH (course:Course)-[:INCLUDES_MATERIAL]->(material:Material)<-[evaluatedMaterial:EVALUATED_MATERIAL]-(user:User)
WITH course, AVG(evaluatedMaterial.rating) AS averageRating
ORDER BY averageRating ASC
LIMIT 1
MATCH (course)<-[:TEACHES_COURSE]-(instructor:Instructor)
RETURN course.name AS CourseName, instructor.firstName + ' ' + instructor.lastName AS InstructorFullName, averageRating AS CourseAverageRating

// 12) Get the most expensive course, its instructors, users and materials
MATCH (course:Course)
WITH course
ORDER BY course.price DESC
LIMIT 1
MATCH (course)<-[:TEACHES_COURSE]-(instructor:Instructor)
MATCH (course)<-[:ENROLLED_FOR_COURSE]-(user:User)
MATCH (course)-[:INCLUDES_MATERIAL]->(material:Material)
RETURN course.name AS CourseName, course.price AS CoursePrice, 
       COLLECT(DISTINCT instructor.firstName + ' ' + instructor.lastName) AS Instructors,
       COLLECT(DISTINCT user.firstName + ' ' + user.lastName) AS Users,
       COLLECT(DISTINCT material.title) AS Materials

// 13) Get the names of the courses, which don't include certification, their instructors and enrolled users
MATCH (course:Course)
WHERE NOT course.certificateOnCompletion
OPTIONAL MATCH (course)<-[:TEACHES_COURSE]-(instructor:Instructor)
OPTIONAL MATCH (course)<-[:ENROLLED_FOR_COURSE]-(user:User)
WITH course, COLLECT(instructor.firstName + ' ' + instructor.lastName) AS instructorNames, COLLECT(user.firstName + ' ' + user.lastName) AS userNames
RETURN course.name AS CourseName,
       REDUCE(i = '', name IN instructorNames | i + CASE WHEN i = '' THEN name ELSE ', ' + name END) AS Instructors,
       REDUCE(u = '', name IN userNames | u + CASE WHEN u = '' THEN name ELSE ', ' + name END) AS Users

// 14) Get users with phone numbers who have enrolled for courses which cost less than 40 dollars and which materials they have downloaded
MATCH (user:User)-[:ENROLLED_FOR_COURSE]->(course:Course)
WHERE course.price < 40
MATCH (user)-[:DOWNLOADED_MATERIAL]->(material:Material)
RETURN user.firstName AS UserFirstName, user.lastName AS UserLastName, user.phoneNumber AS UserPhoneNumber, COLLECT(material.title) AS DownloadedMaterials

// 15) Get the course name with the shortest comment on evaluated material and its name
MATCH (course:Course)-[:INCLUDES_MATERIAL]->(material:Material)<-[evaluatedMaterial:EVALUATED_MATERIAL]-()
WITH course, material, evaluatedMaterial,
     MIN(SIZE(evaluatedMaterial.comment)) AS shortestComment
WHERE shortestComment > 0
RETURN course.name AS CourseName, material.title + ', shortest comment: ' + evaluatedMaterial.comment AS MaterialAndShortestComment
ORDER BY shortestComment ASC
LIMIT 1 
