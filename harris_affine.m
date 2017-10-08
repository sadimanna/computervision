function affineinvpts = harris_affine(img,scaleinvpts)
  %scaleinvpts = harris_laplace(img);
  [h,w]=size(img);
  lenrc = length(scaleinvpts);
  affineinvpts = [];
  epsilon_c = 1;
  for i=1:lenrc
    loop = 0;
    disp(i)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Step 1
    %% Initializing interest points
    xk = scaleinvpts(i,1:2); %row vector
    %% Initializing U-transformation matrix
    U_k = eye(3);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Loop part begins here
    while epsilon_c > 0.05 || loop == 0
      %disp('In the loop...')
      loop = 1; %First Run Complete
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %% Step 2
      xwkm1 = round(transformBackward(xk,U_k)) %xw = [U^(-1)]x -> xw is the point in the transformed Image
      %% Transformed Image
      transformedImage = transformImageBackward(img,U_k);
      %% Transformed Image Dimensions
      [tH,tW] = size(transformedImage);
      %imshow(transformedImage)
      %% Selecting the transformed image domain window W(xw)
      if xwkm1(1)>2 && xwkm1(2)>2 && xwkm1(1)<tH-1 && xwkm1(2)<tW-1
        W = transformedImage(xwkm1(1)-2:xwkm1(1)+2,xwkm1(2)-2:xwkm1(2)+2);
        NA = 0;
      else
        NA=1;
        break
      end
      %% Normalizing the window
      if nnz(W==0)~=25 && nnz(W==0)<10
        W = windownormalize(W);
      else
        break
      end
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %% Step 3
      %disp('Step 3')
      %% Calculating Integration Scale
      si = intscaleselect(W);
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %% Step 4
      %disp('Step 4')
      %% Calculation of optimal s for calculating sigmaD by maximizing isotropic measure
      opts = optdiffscale(si,W);
      sd = opts*si;
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %% Step 5
      %disp('Step 5')
      %% Finding Spatial Localization
      xwk = round(spatialloc(xwkm1,si,sd,W));
      %% Calculating Displacement
      displacement = xwk-xwkm1;
      %% Displacement in Original image
      displacementOrig = transformForward(displacement,U_k);
      %% Calculating location of xk
      xk = xk + displacementOrig;
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %% Step 6
      %disp('Step 6')
      %% Calculation of window at xwk
      if xwk(1)>2 && xwk(2)>2 && xwk(1)<tH-1 && xwk(2)<tW-1
        W = transformedImage(xwk(1)-2:xwk(1)+2,xwk(2)-2:xwk(2)+2);
        NA = 0;
      else
        NA=1;
        break
      end
      %% calculation of the mu matrix
      mu_xwk = harrismeasure_xw(W,si,sd);
      %% Calculating root of mu matrix
      mu_i22 = inv(sqrtm(mu_xwk));
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %% Step 7
      %disp('Step 7')
      %% Making mu_sqrt from 2x2 to 3x3
      mu_i33 = [mu_i22,zeros(2,1);zeros(1,2),1];
      %% Calculating U-transformation Matrix for next step
      U_k = mu_i33*U_k;
      %% Normalizing maximum eigenvalue to 1
      [eigvec,eigval] = eig(U_k);
      eigval = eigval/max(max(eigval));
      U_k = (eigvec*eigval)/(eigvec);
      %% Making the last row of affine transformation matrix equal to zeros expect one in the the last column
      U_k = U_k/U_k(9);
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %% Step 8
      %% Checking Stopping criterion
      lambda_mu_i = eig(mu_i22);
      epsilon_c = 1-min(lambda_mu_i)/max(lambda_mu_i)
    end
    if epsilon_c < 0.05 && NA==0
      %disp(i)
      ismemberpt = ismember(xk',affineinvpts);
      ismemberpt = ismemberpt(1) && ismemberpt(2);
      if ~ismemberpt
        affineinvpts = [affineinvpts;round(xk')];
      end
    end
  end
  
  %%Discarding negative points
%   affine1 = affineinvpts(:,1)>0;
%   affine2 = affineinvpts(:,2)>0;
%   affine3 = affine1&affine2;
%   affinefc = affineinvpts(:,1);
%   affinefc = affinefc(affine3);
%   affinesc = affineinvpts(:,2);
%   affinesc = affinesc(affine3);
%   affineinvpts = [affinefc,affinesc];
end