import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:se7ety/core/functions/image_uploader.dart';
import 'package:se7ety/features/auth/models/doctor_model.dart';
import 'package:se7ety/features/auth/models/patient_model.dart';
import 'package:se7ety/features/auth/models/user_type_enum.dart';
import 'package:se7ety/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitialState());

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? specialization;

  final bioController = TextEditingController();
  final phone1Controller = TextEditingController();
  final phone2Controller = TextEditingController();
  final addressController = TextEditingController();
  final openHourController = TextEditingController();
  final closeHourController = TextEditingController();

  login() async {
    emit(AuthLoadingState());
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      // Role (doctor, patient)
      emit(AuthSuccessState(role: credential.user?.photoURL));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        emit(AuthFailureState("لا يوجد مستخدم بهذا البريد الإلكتروني"));
      } else if (e.code == 'wrong-password') {
        emit(AuthFailureState("كلمة المرور غير صحيحة"));
      } else {
        emit(AuthFailureState("حدث خطأ ما، يرجى المحاولة مرة أخرى"));
      }
    } catch (e) {
      emit(AuthFailureState("حدث خطأ ما، يرجى المحاولة مرة أخرى"));
    }
  }

  register({required UserTypeEnum type}) async {
    emit(AuthLoadingState());
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );
      // after successful registration, update the user's display name
      User? user = credential.user;
      await user?.updateDisplayName(nameController.text);
      //! Use Photo URL as Role
      user?.updatePhotoURL(type == UserTypeEnum.doctor ? "doctor" : "patient");
      // email, uid, name , role

      // then store user data in Firestore
      if (type == UserTypeEnum.doctor) {
        var doctor = DoctorModel(
          uid: user?.uid,
          name: nameController.text,
          email: emailController.text,
        );
        await FirebaseFirestore.instance
            .collection("doctor")
            .doc(user?.uid)
            .set(doctor.toJson());
      } else {
        var patient = PatientModel(
          uid: user?.uid,
          name: nameController.text,
          email: emailController.text,
        );
        await FirebaseFirestore.instance
            .collection("patient")
            .doc(user?.uid)
            .set(patient.toJson());
      }

      emit(AuthSuccessState());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        emit(AuthFailureState("كلمة المرور ضعيفة"));
      } else if (e.code == 'email-already-in-use') {
        emit(AuthFailureState("البريد الإلكتروني مستخدم بالفعل"));
      } else {
        emit(AuthFailureState("حدث خطأ ما، يرجى المحاولة مرة أخرى"));
      }
    } catch (e) {
      emit(AuthFailureState("حدث خطأ ما، يرجى المحاولة مرة أخرى"));
    }
  }

  updateDoctorData(File? pickedImage) async {
    emit(AuthLoadingState());
    try {
      //1) upload file to storage
      String? imageUrl = await uploadImageToCloudinary(pickedImage!);
      if (imageUrl == null) {
        emit(AuthFailureState("فشل في رفع الصورة، يرجى المحاولة مرة أخرى"));
        return;
      }
      // update data in firestore
      var doctor = DoctorModel(
        uid: FirebaseAuth.instance.currentUser?.uid,
        bio: bioController.text,
        phone1: phone1Controller.text,
        phone2: phone2Controller.text,
        address: addressController.text,
        specialization: specialization,
        openHour: openHourController.text,
        closeHour: closeHourController.text,
        image: imageUrl,
        rating: 3,
      );
      await FirebaseFirestore.instance
          .collection("doctor")
          .doc(doctor.uid)
          .update(doctor.toUpdateData());
      emit(AuthSuccessState());
    } on Exception catch (_) {
      emit(AuthFailureState("حدث خطأ ما، يرجى المحاولة مرة أخرى"));
    }
  }
}
