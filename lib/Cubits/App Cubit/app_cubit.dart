
// ignore_for_file: avoid_print, prefer_const_constructors

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_just_extracirricular/Models/Post%20Model.dart';
import 'package:e_just_extracirricular/Models/User%20Model.dart';
import 'package:e_just_extracirricular/Screens/home_screen.dart';
import 'package:e_just_extracirricular/Shared/Components.dart';
import 'package:e_just_extracirricular/Shared/Constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(AppInitialState());

  static AppCubit get(BuildContext context) => BlocProvider.of(context);
  var firestore = FirebaseFirestore.instance;

  var index = 0;


  void changeDrawer(int i) {
    index = i;
    emit(changePageState());
  }

  // Get User
  void getUser() {
    emit(loadingGetUserState());
    firestore
    .collection("Users")
    .doc(uId)
    .get()
    .then((value) {      
      user = UserModel.fromJson(value.data());
      emit(successGetUserState());
    })
    .catchError((error) {
      emit(failedGetUserState(error.toString()));
    });
  }

  // Get Posts
  List<PostModel> posts=[];

  void getPosts() {
    posts.clear();
    emit(loadingGettingPostState());
    firestore
    .collection("Posts")
    .get()
    .then((value) {
      for (var element in value.docs) {
        posts.add(PostModel.fromJson(element.data()));
      }
      emit(successGettingPostState());
    })
    .catchError((error) {
      emit(failedGettingPostState());
    });
  }

  // Upload a Post

  var textController = TextEditingController();
  String? postImage;
  File? postFileImage;

  void pickImage() {
    emit(pickingImageState());
    ImagePicker()
    .pickImage(source: ImageSource.gallery)
    .then((value) {
      postFileImage = File(value!.path);
      emit(successPickingImageState());
      uploadImage(value.name);
    });
  }

  void uploadImage(String imageName) {
    emit(uploadingPostImageState());
    FirebaseStorage
    .instance
    .ref()
    .child("Users/$uId/Posts/$imageName")
    .putFile(postFileImage!)
    .then((file) {
      emit(successUploadingPostImageState());
      file.ref.getDownloadURL().then((value) {postImage=value;});
    })
    .catchError((error) {
      print(error.toString());
      emit(failedUploadingPostImageState());
    });
  }

  void removeImage() {
    postImage=null;
    postFileImage=null;
    emit(removedPostImageState());
  }

  void uploadPost(BuildContext context) {
    emit(uploadingPostState());
    var model = PostModel(
      postImage: postImage, 
      postText: textController.text, 
      posterName: user.name, 
      posterProfilePicture: user.profilePicture, 
      posteruId: user.uId,
      date: DateTime.now().toString());
    firestore
    .collection("Posts")
    .add(model.toJson())
    .then((value) {
      emit(successUploadingPostState());
      navigateTo(context: context, destination: Home_Screen());
    })
    .catchError((error) {
      emit(failedUploadingPostState());
    });
  }

}