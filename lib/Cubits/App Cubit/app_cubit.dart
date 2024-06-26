
// ignore_for_file: avoid_print, prefer_const_constructors, non_constant_identifier_names, prefer_null_aware_operators

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_just_extracirricular/Models/Post%20Model.dart';
import 'package:e_just_extracirricular/Models/User%20Model.dart';
import 'package:e_just_extracirricular/Screens/clubs_screen.dart';
import 'package:e_just_extracirricular/Screens/feed_screen.dart';
import 'package:e_just_extracirricular/Screens/home_screen.dart';
import 'package:e_just_extracirricular/Shared/Components.dart';
import 'package:e_just_extracirricular/Shared/Constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(AppInitialState());

  static AppCubit get(BuildContext context) => BlocProvider.of(context);
  var firestore = FirebaseFirestore.instance;

  var index = 0;

  var screens = [Feed_Screen(),Clubs_Screen()];

  void changeDrawer(int i) {
    index = i;
    emit(changePageState());
  }

  var gotUser = false;
  var gotPosts = false;
  var gotClubs = false;
  List<bool> gotStates = [];

  // Get User
  UserModel? user, retrieving_user;

  void getUser() {
    emit(loadingGetUserState());
    firestore
    .collection("Users")
    .doc(uId)
    .get()
    .then((value) {      
      user = UserModel.fromJson(value.data()!);
      retrieving_user = user!.clone();
      emit(successGetUserState());
    })
    .catchError((error) {
      emit(failedGetUserState(error.toString()));
    });
  }

  // Get Posts
  List<PostModel> posts=[];

  void getPosts() {
    emit(loadingGettingPostState());
    firestore
    .collection("Posts")
    .orderBy("date", descending: true)
    .get()
    .then((value) {
      posts.clear();
      for (var element in value.docs) {
        var temp_post = PostModel.fromJson(element.data());
        if (checkPost(temp_post)) {
          posts.add(PostModel.fromJson(element.data()));
        }
      }
      emit(successGettingPostState());
    })
    .catchError((error) {
      emit(failedGettingPostState(error.toString()));
    });
  }

    
  bool checkPost(PostModel temp_post) {
    if (user!.following.contains(temp_post.posteruId)) {
      if (temp_post.eventDate==null) {
        return true;
      } else if (DateTime.now().isBefore(DateTime.parse(temp_post.eventDate!))) {
        return true;
      }
     }
    return false;
  }



  // Get Clubs
  List<UserModel> clubs = [];

  void getClubs() {
    emit(loadingGettingClubsState());
    clubs.clear();
    firestore
    .collection("Users")
    .get()
    .then((value) {
      for (var element in value.docs) {
        var temp_model = UserModel.fromJson(element.data());
        if (temp_model.isClub) {
        clubs.add(temp_model);
        }
      }
      emit(successGettingClubsState());
    })
    .catchError((error) {
      emit(failedGettingClubsState(error.toString()));
    });
  }

  // Upload a Post

  var textController = TextEditingController();
  String? postImage;
  File? postFileImage;
  DateTime? eventDate;

  void chooseDate(BuildContext context) {
      showDatePicker(
      context: context,
      firstDate: DateTime(2010),
      lastDate: DateTime(2030))
      .then((value) {
        if (value!=null)  {
        chooseTime(context, value);
        } else {
          eventDate=null;
          emit(nulledDateState());
        }
      });
    }

  void chooseTime(BuildContext context, DateTime date) {
    showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      )
      .then((value) {
        var time = value;
        if (time==null) {
          eventDate=null;
          emit(nulledDateState());
        } else {
        eventDate=DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        emit(choosedDateState());
        }
      });
  }

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
      going: [],
      eventDate: eventDate==null ? null : eventDate.toString(),
      postImage: postImage, 
      postText: textController.text, 
      posterName: user!.name, 
      posterProfilePicture: user!.profilePicture, 
      posteruId: user!.uId,
      postDate: DateTime.now().toString());
    firestore
    .collection("Posts")
    .add(model.toJson())
    .then((value) {  
      getPosts();
      emit(successUploadingPostState());
      navigateTo(context: context, destination: Home_Screen());
    })
    .catchError((error) {
      emit(failedUploadingPostState());
    });
  }

  // Following

  void followClub(String followeduId) {
    if (user!.following.contains(followeduId)) {
    user!.following.remove(followeduId);
    } else {
      user!.following.add(followeduId);
    }
    firestore
    .collection("Users")
    .doc(user!.uId)
    .update(user!.toJson())
    .then((value) {
      retrieving_user = user!.clone();
      emit(successFollowClubState());
      getPosts();
    })
    .catchError((error) {
      user = retrieving_user!.clone();
      emit(failedFollowingClubState(error.toString()));
    });
  }
}
