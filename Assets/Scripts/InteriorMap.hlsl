

float4 checkIfCloser(float3 rayDir, float3 rayStartPos, float3 planePos, float3 planeNormal, UnityTexture2DArray PlaneTex, float index, float4 colorAndDist, UnitySamplerState ss, float roomCount)
{
    //Get the distance to the plane with ray-plane intersection
    //http://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-plane-and-ray-disk-intersection
    //We are always intersecting with the plane so we dont need to spend time checking that			
    float t = dot(planePos - rayStartPos, planeNormal) / dot(planeNormal, rayDir);

    //At what position is the ray intersecting with the plane - use this if you need uv coordinates
    float3 intersectPos = rayStartPos + rayDir * t;
    float2 ipos;

    //check the wall and assign the correct UV to ipos
    if( planeNormal.x == -1 ) // Left wall    
    ipos = float2(intersectPos.y, -intersectPos.z);
    else if( planeNormal.x == 1 ) // Right wall    
    ipos = float2(-intersectPos.y, -intersectPos.z);
    else if(planeNormal.y == 1) // Ceiling
    ipos = float2(intersectPos.x, -intersectPos.z);
    else if(planeNormal.y == -1) // floor
    ipos = float2(-intersectPos.x, -intersectPos.z);
    else    // Front and Back wall
    ipos = float2(planeNormal.z * intersectPos.x, intersectPos.y);
    

    //If the distance is closer to the camera than the previous best distance
    if (t < colorAndDist.w)
    {
        //This distance is now the best distance
        colorAndDist.w = t;

        //Set the color that belongs to this wall	
        //ipos = float2(ipos.x + 0.5, ipos.y + 0.5);		
        colorAndDist.rgb = SAMPLE_TEXTURE2D_ARRAY(PlaneTex, ss, ipos * roomCount, index);
    }

    return colorAndDist;
}

void InteriorMapping_float(float3 objectViewDir, float3 objectPos, float roomCount, UnitySamplerState ss,
UnityTexture2DArray CubeTex,  out float4 colorAndDist)
{
    //The view direction of the camera to this fragment in local space
    float3 rayDir = normalize(objectViewDir);

    //The local position of this fragment
    float3 rayStartPos = objectPos;

    //Important to start inside the house or we will display one of the outer walls
    rayStartPos += rayDir * 0.0001;


    //Init the loop with a float4 to make it easier to return from a function
    //colorAndDist.rgb is the color that will be displayed
    //colorAndDist.w is the shortest distance to a wall so far so we can find which wall is the closest
    colorAndDist = float4(float3(1,1,1), 100000000.0);

    float wallDistance = 1/roomCount;

    float3 upVec = float3(0, 1, 0);	
    float3 rightVec = float3(1, 0, 0);
    float3 forwardVec = float3(0, 0, 1);


    //Intersection 1: Wall / roof (y)
    //Camera is looking up if the dot product is > 0 = Roof
    if (dot(upVec, rayDir) > 0)
    {				
        //The local position of the roof
        float3 wallPos = (ceil(rayStartPos.y / wallDistance) * wallDistance) * upVec;

        //Check if the roof is intersecting with the ray, if so set the color and the distance to the roof and return it
        colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, upVec, CubeTex, 4, colorAndDist, ss, roomCount);
    }
    //Floor
    else
    {
        float3 wallPos = ((ceil(rayStartPos.y / wallDistance) - 1.0) * wallDistance) * upVec;

        colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, upVec * -1, CubeTex, 5, colorAndDist, ss, roomCount);
        //colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, upVec * -1, color1, colorAndDist);
    }
    

    //Intersection 2: Right wall (x)
    if (dot(rightVec, rayDir) > 0)
    {
        float3 wallPos = (ceil(rayStartPos.x / wallDistance) * wallDistance) * rightVec;

        colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, rightVec, CubeTex, 0, colorAndDist, ss, roomCount);
    }
    else
    {
        float3 wallPos = ((ceil(rayStartPos.x / wallDistance) - 1.0) * wallDistance) * rightVec;

        colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, rightVec * -1, CubeTex, 1, colorAndDist, ss, roomCount);
    }


    //Intersection 3: Forward wall (z)
    if (dot(forwardVec, rayDir) > 0)
    {
        float3 wallPos = (ceil(rayStartPos.z / wallDistance) * wallDistance) * forwardVec;

        colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, forwardVec, CubeTex, 3, colorAndDist, ss, roomCount);
    }
    else
    {
        float3 wallPos = ((ceil(rayStartPos.z / wallDistance) - 1.0) * wallDistance) * forwardVec;

        colorAndDist = checkIfCloser(rayDir, rayStartPos, wallPos, forwardVec * -1, CubeTex, 2, colorAndDist, ss, roomCount);
    }   
    

    
}

